#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
WhisperEngine — Headless MLX Whisper backend for Whisper Studio 3.0.5 (macOS).
Communicates strictly over stdin/stdout JSON Lines (one JSON object per line).
"""

import os
import sys
import re
import json
import time
import shutil
import threading
import subprocess
import multiprocessing
from pathlib import Path

# Preserve real stdout exclusively for JSON Lines IPC; route all library prints to stderr.
_REAL_STDOUT = sys.stdout
sys.stdout = sys.stderr

os.environ.setdefault("HF_HUB_DOWNLOAD_TIMEOUT", "300")
os.environ.setdefault("HF_HUB_ETAG_TIMEOUT", "60")

if getattr(sys, "frozen", False):
    DIR_CORRENTE = Path(sys._MEIPASS)
else:
    DIR_CORRENTE = Path(__file__).resolve().parent

_EMIT_LOCK = threading.Lock()


def emit_event(event_name: str, **fields):
    payload = {"event": event_name}
    payload.update(fields)
    line = json.dumps(payload, ensure_ascii=False)
    with _EMIT_LOCK:
        try:
            _REAL_STDOUT.write(line + "\n")
            _REAL_STDOUT.flush()
        except Exception:
            pass


def find_ffmpeg() -> str:
    candidates = []
    if getattr(sys, "frozen", False):
        meipass = Path(sys._MEIPASS)
        candidates.extend([
            meipass / "ffmpeg",
            meipass.parent / "ffmpeg",
            meipass.parent / "Resources" / "ffmpeg",
            meipass.parent / "Frameworks" / "ffmpeg",
            meipass.parent / "MacOS" / "ffmpeg",
        ])
    exe_p = Path(sys.executable).resolve()
    candidates.extend([
        exe_p.parent / "ffmpeg",
        exe_p.parent.parent / "Resources" / "ffmpeg",
        DIR_CORRENTE / "ffmpeg",
        DIR_CORRENTE.parent / "ffmpeg",
        Path("/opt/homebrew/bin/ffmpeg"),
        Path("/usr/local/bin/ffmpeg"),
    ])

    for c in candidates:
        if c.is_file():
            try:
                os.chmod(c, 0o755)
            except Exception:
                pass
            if os.access(c, os.X_OK):
                return str(c.resolve())

    which_ff = shutil.which("ffmpeg")
    if which_ff:
        return which_ff
    return "ffmpeg"


FFMPEG_BIN = find_ffmpeg()
if FFMPEG_BIN and os.path.isabs(FFMPEG_BIN):
    ff_dir = str(Path(FFMPEG_BIN).parent)
    if ff_dir not in os.environ.get("PATH", ""):
        os.environ["PATH"] = f"{ff_dir}:{os.environ.get('PATH', '')}"


def apply_mlx_whisper_patch():
    """Force mlx_whisper.audio to use the resolved arm64 ffmpeg binary."""
    try:
        import mlx_whisper.audio
        import mlx.core as mx
        import numpy as np

        ff_bin = FFMPEG_BIN or find_ffmpeg()
        if not ff_bin:
            return

        def patch_load_audio(file, sr=16000, from_stdin=False):
            if from_stdin:
                cmd = [ff_bin, "-i", "pipe:0"]
            else:
                cmd = [ff_bin, "-nostdin", "-i", str(file)]
            cmd.extend([
                "-threads", "0",
                "-f", "s16le",
                "-ac", "1",
                "-acodec", "pcm_s16le",
                "-ar", str(sr),
                "-",
            ])
            try:
                out = subprocess.run(cmd, capture_output=True, check=True).stdout
            except subprocess.CalledProcessError as err:
                err_msg = err.stderr.decode("utf-8", errors="replace") if err.stderr else str(err)
                raise RuntimeError(f"FFmpeg decoding error: {err_msg}") from err
            return mx.array(np.frombuffer(out, np.int16)).flatten().astype(mx.float32) / 32768.0

        mlx_whisper.audio.load_audio = patch_load_audio
    except Exception:
        pass


def get_file_duration(file_path: str) -> float:
    ff = FFMPEG_BIN or find_ffmpeg()
    cmd = [ff, "-i", str(file_path)]
    try:
        res = subprocess.run(cmd, stderr=subprocess.PIPE, stdout=subprocess.PIPE, text=True, timeout=15)
        m = re.search(r"Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)", res.stderr)
        if m:
            h, minuti, s = float(m.group(1)), float(m.group(2)), float(m.group(3))
            return max(1.0, h * 3600 + minuti * 60 + s)
    except Exception:
        pass
    return 60.0


def generate_output_base_stem(p_in: Path, lang: str = "it") -> str:
    """
    Generate clean transcription output base stem (without extension):
    - Preserves custom user titles (e.g. 'EGI 12 novembre.m4a' -> 'Trascrizione EGI 12 novembre')
    - Formats timestamps into 'gg-mm-aa - oo.mm' while stripping generic recorder words
    """
    stem = p_in.stem
    prefix = "Trascrizione" if lang == "it" else "Transcription"

    m1 = re.search(r"(20\d{2})[-_.]?(\d{2})[-_.]?(\d{2})[-_ ]+(\d{2})[-_.]?(\d{2})", stem)
    m2 = re.search(r"(\d{2})[-_.](\d{2})[-_.](20\d{2}|\d{2})[-_ ]+(\d{2})[-_.](\d{2})", stem)

    matched_span = None
    formatted_date = None

    if m1:
        matched_span = m1.span()
        anno_full, mese, giorno, ora, minuti = m1.groups()
        anno_breve = anno_full[-2:]
        formatted_date = f"{giorno}-{mese}-{anno_breve} - {ora}.{minuti}"
    elif m2:
        matched_span = m2.span()
        giorno, mese, anno_raw, ora, minuti = m2.groups()
        anno_breve = anno_raw[-2:]
        formatted_date = f"{giorno}-{mese}-{anno_breve} - {ora}.{minuti}"

    if formatted_date:
        start, end = matched_span
        rest = (stem[:start] + " " + stem[end:]).strip()

        generic_pattern = r"(?i)(?:^|[\s_.-])(?:registratore|registrazione|recording|audio|voice|vocale|rec|memo|nuova registrazione|new recording)(?:$|[\s_.-])"
        prev = None
        cleaned = rest
        while prev != cleaned:
            prev = cleaned
            cleaned = re.sub(generic_pattern, " ", cleaned).strip()

        cleaned = re.sub(r"[-_ ]+", " ", cleaned).strip(" -_")

        if cleaned:
            nuovo_nome = f"{prefix} {cleaned} - {formatted_date}"
        else:
            nuovo_nome = f"{prefix} {formatted_date}"
    else:
        pulito = re.sub(
            r"(?i)^(?:registratore|registrazione|recording|nuova registrazione|new recording)\s*[-_]?\s*",
            "",
            stem,
        ).strip(" -_")
        if not pulito:
            pulito = stem
        nuovo_nome = f"{prefix} {pulito}"

    return re.sub(r" +", " ", nuovo_nome).strip()


def resolve_unique_output_paths(p_in: Path, target_dir: Path, formats: list, lang: str = "it", session_reserved: set = None) -> dict:
    """
    Resolve collision-free output paths for requested formats (.txt, .docx).
    Shared progressive counter ' (2)', ' (3)' keeps .txt and .docx paired.
    """
    base_stem = generate_output_base_stem(p_in, lang=lang)
    target_dir = Path(target_dir).resolve()
    target_dir.mkdir(parents=True, exist_ok=True)

    counter = 1
    while True:
        stem_candidate = base_stem if counter == 1 else f"{base_stem} ({counter})"
        collision = False
        candidates = {}
        for fmt in formats:
            cand = target_dir / f"{stem_candidate}.{fmt}"
            candidates[fmt] = cand
            if cand.exists():
                collision = True
                break
            if session_reserved is not None and str(cand.resolve()) in session_reserved:
                collision = True
                break

        if not collision:
            if session_reserved is not None:
                for cand in candidates.values():
                    session_reserved.add(str(cand.resolve()))
            return candidates

        counter += 1


def atomic_write_text(p_out: Path, text: str):
    tmp_path = p_out.with_name(f".{p_out.name}.tmp.{os.getpid()}")
    try:
        with open(tmp_path, "w", encoding="utf-8") as f:
            f.write(text)
        os.replace(tmp_path, p_out)
    finally:
        if tmp_path.exists():
            try:
                tmp_path.unlink()
            except Exception:
                pass


def atomic_write_docx(p_out: Path, title: str, paragraphs: list):
    from docx import Document

    tmp_path = p_out.with_name(f".{p_out.name}.tmp.{os.getpid()}")
    try:
        doc = Document()
        doc.add_heading(title, level=1)
        for par in paragraphs:
            doc.add_paragraph(par)
        doc.save(str(tmp_path))
        os.replace(tmp_path, p_out)
    finally:
        if tmp_path.exists():
            try:
                tmp_path.unlink()
            except Exception:
                pass


def is_model_locally_cached(repo_id: str):
    """Check whether model weights and config.json are completely present in local HF cache."""
    try:
        from huggingface_hub import snapshot_download

        local_dir = snapshot_download(repo_id=repo_id, local_files_only=True)
        p = Path(local_dir)
        if (p / "config.json").exists():
            for w in ("weights.safetensors", "weights.npz", "model.safetensors"):
                wf = p / w
                if wf.exists() and wf.stat().st_size > 10_000_000:
                    return str(p)
    except Exception:
        pass
    return None


def check_or_download_model(repo_id: str, lang: str = "it", check_abort=None):
    cached_path = is_model_locally_cached(repo_id)
    if cached_path:
        return True, cached_path, ""

    if check_abort and check_abort():
        return False, repo_id, "Download annullato" if lang == "it" else "Download cancelled"

    msg_start = f"Avvio download {repo_id} da Hugging Face..." if lang == "it" else f"Downloading {repo_id} from Hugging Face..."
    emit_event("download_progress", percent=0, message=msg_start)

    try:
        from huggingface_hub import snapshot_download
        from huggingface_hub.utils import tqdm as _BaseTqdm

        os.environ["HF_HUB_DOWNLOAD_TIMEOUT"] = "300"
        os.environ["HF_HUB_ETAG_TIMEOUT"] = "60"

        last_emit = [0.0]
        has_byte_bar = [False]

        class _AbortableTqdm(_BaseTqdm):
            def __init__(self, *args, **kwargs):
                if check_abort and check_abort():
                    raise InterruptedError("Download cancelled")
                kwargs["disable"] = False
                kwargs.setdefault("file", sys.stderr)
                super().__init__(*args, **kwargs)
                self._dl_start_ts = time.time()
                self._last_speed_ts = self._dl_start_ts
                self._last_speed_n = self.n
                self._smooth_rate = 0.0
                self._is_byte_bar = (kwargs.get("unit") == "B") or ((self.total or 0) > 100_000)
                if self._is_byte_bar:
                    has_byte_bar[0] = True

            def update(self, n=1):
                if check_abort and check_abort():
                    raise InterruptedError("Download cancelled")
                res = super().update(n)
                now = time.time()
                if not self.total or self.total <= 0:
                    return res
                if not self._is_byte_bar and has_byte_bar[0]:
                    return res

                if now - last_emit[0] >= 0.45 or self.n >= self.total:
                    last_emit[0] = now
                    perc = max(0, min(99, int((self.n / self.total) * 100)))
                    if self._is_byte_bar:
                        # Use decimal MB (1_000_000) to match macOS Finder & Activity Monitor
                        mb_done = self.n / 1_000_000
                        mb_total = self.total / 1_000_000
                        dt = now - self._last_speed_ts
                        if dt >= 0.4:
                            inst_rate = max(0.0, (self.n - self._last_speed_n) / dt)
                            self._smooth_rate = (
                                inst_rate
                                if self._smooth_rate <= 0
                                else (0.55 * inst_rate + 0.45 * self._smooth_rate)
                            )
                            self._last_speed_ts = now
                            self._last_speed_n = self.n
                        speed_mb = self._smooth_rate / 1_000_000
                        if lang == "it":
                            msg = f"Download modello ({perc}%) • {mb_done:.0f} / {mb_total:.0f} MB • {speed_mb:.1f} MB/s"
                        else:
                            msg = f"Downloading model ({perc}%) • {mb_done:.0f} / {mb_total:.0f} MB • {speed_mb:.1f} MB/s"
                    else:
                        msg = (
                            f"Download modello in corso ({perc}%)..."
                            if lang == "it"
                            else f"Downloading model ({perc}%)..."
                        )
                    emit_event("download_progress", percent=perc, message=msg)
                return res

        downloaded_dir = snapshot_download(
            repo_id=repo_id,
            local_files_only=False,
            max_workers=2,
            tqdm_class=_AbortableTqdm,
        )
        if check_abort and check_abort():
            return False, repo_id, "Download annullato" if lang == "it" else "Download cancelled"

        verified_path = is_model_locally_cached(repo_id) or downloaded_dir
        msg_done = "Download completato con successo!" if lang == "it" else "Download completed successfully!"
        emit_event("download_progress", percent=100, message=msg_done)
        return True, str(verified_path), ""
    except InterruptedError:
        return False, repo_id, "Download annullato" if lang == "it" else "Download cancelled"
    except Exception as e:
        if check_abort and check_abort():
            return False, repo_id, "Download annullato" if lang == "it" else "Download cancelled"
        return False, repo_id, str(e)


class ThreadStdoutInterceptor:
    def __init__(self, durata_file, callback_progresso, check_abort, check_pause, fallback_stream=None):
        self.durata_file = max(float(durata_file), 1.0)
        self.callback_progresso = callback_progresso
        self.check_abort = check_abort
        self.check_pause = check_pause
        self.fallback_stream = fallback_stream or sys.stderr
        self.start_time = time.time()
        self.paused_accum = 0.0
        self.regex = re.compile(r"-->\s*([0-9:\.]+)")
        self.ultimo_invio = 0.0
        self.encoding = "utf-8"
        self.errors = "replace"

    def write(self, text):
        if not text:
            return 0
        if self.fallback_stream:
            try:
                self.fallback_stream.write(text)
            except Exception:
                pass

        if self.check_abort():
            raise InterruptedError("Trascrizione interrotta")
        if self.check_pause():
            p_start = time.time()
            while self.check_pause():
                time.sleep(0.1)
                if self.check_abort():
                    raise InterruptedError("Trascrizione interrotta")
            self.paused_accum += (time.time() - p_start)

        m = self.regex.search(text)
        if m:
            ts_str = m.group(1).strip()
            try:
                parti = ts_str.split(":")
                if len(parti) == 3:
                    sec_att = float(parti[0]) * 3600 + float(parti[1]) * 60 + float(parti[2])
                elif len(parti) == 2:
                    sec_att = float(parti[0]) * 60 + float(parti[1])
                else:
                    sec_att = float(parti[0])

                sec_att = min(sec_att, self.durata_file)
                perc = int((sec_att / self.durata_file) * 100)
                trascorso = max(0.1, (time.time() - self.start_time) - self.paused_accum)
                if sec_att > 0 and trascorso > 0:
                    velocita = sec_att / trascorso
                    rimasto = max(0.0, (self.durata_file - sec_att) / velocita)
                else:
                    rimasto = 0.0

                adesso = time.time()
                if adesso - self.ultimo_invio >= 0.25 or perc >= 100:
                    self.ultimo_invio = adesso
                    self.callback_progresso(sec_att, perc, trascorso, rimasto)
            except Exception:
                pass
        return len(text)

    def flush(self):
        if self.fallback_stream:
            try:
                self.fallback_stream.flush()
            except Exception:
                pass

    def isatty(self):
        return False

    def writable(self):
        return True

    def readable(self):
        return False

    def seekable(self):
        return False


class EngineController:
    def __init__(self, batch_cfg: dict):
        self.cmd_type = batch_cfg.get("cmd", "start_batch")
        self.model_repo = batch_cfg["model_repo"]
        self.lingua_mode = batch_cfg.get("language", "it")
        self.formati = batch_cfg.get("formats", ["docx"])
        self.ui_lang = batch_cfg.get("ui_lang", "it")
        dest_raw = batch_cfg.get("dest_dir")
        self.dest_dir = Path(dest_raw).resolve() if dest_raw else None
        self.files = batch_cfg.get("files", [])

        self.lock = threading.RLock()
        self.abort_requested = False
        self.is_paused = False
        self.start_time_globale = 0.0
        self.paused_accum_globale = 0.0
        self.pause_start_ts = 0.0
        self.secondi_fatti_fino_a_qui = 0.0
        self.session_reserved = set()

    def pause(self):
        with self.lock:
            if not self.is_paused:
                self.is_paused = True
                self.pause_start_ts = time.time()

    def resume(self):
        with self.lock:
            if self.is_paused:
                if self.pause_start_ts > 0:
                    self.paused_accum_globale += (time.time() - self.pause_start_ts)
                self.pause_start_ts = 0.0
                self.is_paused = False

    def cancel(self):
        with self.lock:
            self.abort_requested = True
            self.is_paused = False

    def handle_command(self, cmd: dict):
        action = cmd.get("cmd")
        if action == "pause":
            self.pause()
        elif action == "resume":
            self.resume()
        elif action == "cancel":
            self.cancel()
        elif action == "append_files":
            new_files = cmd.get("files", [])
            with self.lock:
                self.files.extend(new_files)
        elif action == "remove_file":
            fid = cmd.get("id")
            with self.lock:
                kept = []
                for f in self.files:
                    if f.get("id") == fid and f.get("_status") != "running":
                        if f.get("_status") == "completed":
                            dur = max(1.0, float(f.get("duration") or 60.0))
                            self.secondi_fatti_fino_a_qui = max(0.0, self.secondi_fatti_fino_a_qui - dur)
                        continue
                    kept.append(f)
                self.files = kept
        elif action == "reorder_files":
            ordered_ids = cmd.get("ordered_ids") or []
            order_map = {fid: idx for idx, fid in enumerate(ordered_ids)}
            with self.lock:
                fixed = [f for f in self.files if f.get("_status", "waiting") != "waiting"]
                waiting = [f for f in self.files if f.get("_status", "waiting") == "waiting"]
                waiting.sort(key=lambda f: (0, order_map[f["id"]]) if f.get("id") in order_map else (1, 0))
                self.files = fixed + waiting

    def run_batch(self):
        apply_mlx_whisper_patch()
        import mlx_whisper
        import mlx.core as mx

        cached_before = is_model_locally_cached(self.model_repo) is not None
        emit_event("model_cached_status", cached=cached_before, repo=self.model_repo)

        ok, resolved_path, err_dl = check_or_download_model(
            self.model_repo,
            lang=self.ui_lang,
            check_abort=lambda: self.abort_requested,
        )
        if self.abort_requested:
            emit_event("batch_cancelled")
            return
        if not ok:
            emit_event("fatal_error", error=err_dl)
            return

        emit_event("model_ready", resolved_path=resolved_path)

        if self.cmd_type == "download_model" or not self.files:
            emit_event("batch_completed", completed_count=0, last_output_dir="")
            return

        self.start_time_globale = time.time()
        completati = 0
        last_output_dir = ""

        try:
            while not self.abort_requested:
                item = None
                total_dur = 0.0
                total_count = 0
                idx_counter = 0
                with self.lock:
                    for cand in self.files:
                        if cand.get("_status", "waiting") == "waiting":
                            item = cand
                            cand["_status"] = "running"
                            break
                    idx_counter = sum(1 for f in self.files if f.get("_status") in ("completed", "error", "running"))
                    total_count = len(self.files)
                    total_dur = max(1.0, sum(max(1.0, float(f.get("duration") or 60.0)) for f in self.files))

                if item is None:
                    break

                fid = item["id"]
                p_in = Path(item["path"])
                durata_file = max(1.0, float(item.get("duration") or get_file_duration(str(p_in))))
                eff_dest_dir = self.dest_dir if self.dest_dir else p_in.parent
                last_output_dir = str(eff_dest_dir)

                emit_event(
                    "file_started",
                    id=fid,
                    path=str(p_in),
                    index=idx_counter,
                    total=total_count,
                )

                def on_chunk(sec_att, perc_file, t_trasc, t_rim, _fid=fid, _dur=durata_file):
                    with self.lock:
                        sec_totali_fatti = self.secondi_fatti_fino_a_qui + min(sec_att, _dur)
                        dur_tot = max(1.0, sum(max(1.0, float(f.get("duration") or 60.0)) for f in self.files))
                        perc_glob = min(100, int((sec_totali_fatti / dur_tot) * 100))
                        extra_p = (time.time() - self.pause_start_ts) if (self.is_paused and self.pause_start_ts > 0) else 0.0
                        tempo_reale = max(0.1, (time.time() - self.start_time_globale) - self.paused_accum_globale - extra_p)
                        vel = sec_totali_fatti / tempo_reale
                        rim_tot = max(0.0, (dur_tot - sec_totali_fatti) / vel) if vel > 0 else 0.0

                    emit_event(
                        "file_progress",
                        id=_fid,
                        file_percent=perc_file,
                        file_elapsed=round(t_trasc, 2),
                        file_remaining=round(t_rim, 2),
                        total_percent=perc_glob,
                        total_elapsed=round(tempo_reale, 2),
                        total_remaining=round(rim_tot, 2),
                    )

                interceptor = ThreadStdoutInterceptor(
                    durata_file=durata_file,
                    callback_progresso=on_chunk,
                    check_abort=lambda: self.abort_requested,
                    check_pause=lambda: self.is_paused,
                    fallback_stream=sys.stderr,
                )
                sys.stdout = interceptor

                lingua = None if self.lingua_mode == "auto" else self.lingua_mode
                kwargs = {
                    "path_or_hf_repo": resolved_path,
                    "verbose": True,
                    "condition_on_previous_text": False,
                    "hallucination_silence_threshold": 2.0,
                }
                if lingua:
                    kwargs["language"] = lingua

                try:
                    try:
                        mx.clear_cache()
                    except Exception:
                        pass

                    risultato = mlx_whisper.transcribe(str(p_in), **kwargs)

                    segments = risultato.get("segments", [])
                    paragrafi = []
                    buffer = []
                    last_short_norm = None
                    for seg in segments:
                        t = seg.get("text", "").strip()
                        if t:
                            norm = t.lower().strip(".,!?;:…\"'()[]{}")
                            is_short = len(norm.split()) <= 3
                            if is_short and norm and norm == last_short_norm:
                                continue
                            last_short_norm = norm if is_short else None
                            buffer.append(t)
                            if len(buffer) >= 4:
                                paragrafi.append(" ".join(buffer))
                                buffer = []
                    if buffer:
                        paragrafi.append(" ".join(buffer))
                    testo_completo = "\n\n".join(paragrafi)

                    paths_risolti = resolve_unique_output_paths(
                        p_in=p_in,
                        target_dir=eff_dest_dir,
                        formats=self.formati,
                        lang=self.ui_lang,
                        session_reserved=self.session_reserved,
                    )

                    outputs = []
                    for fmt in self.formati:
                        p_out = paths_risolti[fmt]
                        if fmt == "docx":
                            atomic_write_docx(p_out, p_out.stem, paragrafi)
                        else:
                            atomic_write_text(p_out, testo_completo)
                        outputs.append(str(p_out))

                    with self.lock:
                        item["_status"] = "completed"
                        self.secondi_fatti_fino_a_qui += durata_file
                    completati += 1
                    emit_event("file_completed", id=fid, outputs=outputs)

                except InterruptedError:
                    with self.lock:
                        item["_status"] = "cancelled"
                    break
                except Exception as e:
                    with self.lock:
                        item["_status"] = "error"
                        self.secondi_fatti_fino_a_qui += durata_file
                    emit_event("file_error", id=fid, error=str(e))
                finally:
                    sys.stdout = sys.stderr
                    try:
                        mx.clear_cache()
                    except Exception:
                        pass

            if self.abort_requested:
                emit_event("batch_cancelled")
            else:
                emit_event("batch_completed", completed_count=completati, last_output_dir=last_output_dir)
        finally:
            sys.stdout = sys.stderr
            try:
                mx.clear_cache()
            except Exception:
                pass


def main():
    if len(sys.argv) >= 3 and sys.argv[1] == "--probe":
        dur = get_file_duration(sys.argv[2])
        _REAL_STDOUT.write(json.dumps({"duration": dur}) + "\n")
        _REAL_STDOUT.flush()
        return

    if len(sys.argv) >= 3 and sys.argv[1] == "--check-cache":
        cached = is_model_locally_cached(sys.argv[2]) is not None
        _REAL_STDOUT.write(json.dumps({"cached": cached, "repo": sys.argv[2]}) + "\n")
        _REAL_STDOUT.flush()
        return

    # Defensive guard: never allow child/fork helper invocations with extra CLI flags
    # (e.g., Python -c or multiprocessing workers) to read/steal lines from parent stdin.
    if len(sys.argv) > 1:
        sys.stderr.write(f"WhisperEngine ignoring unexpected helper invocation args: {sys.argv[1:]}\n")
        sys.stderr.flush()
        return

    first_line = sys.stdin.readline()
    if not first_line:
        emit_event("batch_cancelled")
        return

    try:
        first_cmd = json.loads(first_line)
    except Exception as e:
        emit_event("fatal_error", error=f"Invalid JSON command: {e}")
        return

    if first_cmd.get("cmd") == "cancel":
        emit_event("batch_cancelled")
        return

    if first_cmd.get("cmd") not in ("start_batch", "download_model"):
        emit_event("fatal_error", error="First command must be start_batch or download_model")
        return

    controller = EngineController(first_cmd)

    def _stdin_loop():
        for raw in sys.stdin:
            raw = raw.strip()
            if not raw:
                continue
            try:
                cmd = json.loads(raw)
                controller.handle_command(cmd)
            except Exception:
                pass

    t_in = threading.Thread(target=_stdin_loop, daemon=True)
    t_in.start()

    controller.run_batch()


if __name__ == "__main__":
    multiprocessing.freeze_support()
    main()
