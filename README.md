<p align="center">
  <img src="assets/wispr.png" width="128" height="128" alt="Whisper Studio App Icon">
</p>

# Whisper Studio

[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Windows-blue?logo=apple&logoColor=white)](https://github.com/Ritolino/WhisperStudio)
[![macOS Engine](https://img.shields.io/badge/macOS-SwiftUI%20%2B%20Apple%20MLX-purple?logo=apple)](https://github.com/ml-explore/mlx-examples/tree/main/whisper)
[![Windows Engine](https://img.shields.io/badge/Windows-PyQt6%20%2B%20CUDA%20%2F%20CPU-brightgreen?logo=nvidia)](https://developer.nvidia.com/cuda-toolkit)
[![macOS Release](https://img.shields.io/badge/macOS%20Release-v3.0.5-orange)](https://github.com/Ritolino/WhisperStudio/releases/tag/v3.0.5)
[![Windows Release](https://img.shields.io/badge/Windows%20Release-v3.0.5-orange)](https://github.com/Ritolino/WhisperStudio/releases/tag/v3.0.5)
[![License](https://img.shields.io/badge/License-MIT-brightgreen.svg)](LICENSE)

A **privacy-first, 100% locally executing** native audio and video transcription studio purpose-built for **macOS** (Native Swift 6 / SwiftUI + Apple Silicon MLX) and **Windows** (PyQt6 + NVIDIA CUDA 12 / CPU `INT8`). Designed as a zero-subscription, zero-telemetry desktop alternative to cloud transcription services and heavy PyTorch wrappers, exporting directly to **Plain Text (`.txt`)** and **Microsoft Word (`.docx`)**.

[**🇮🇹 Leggi il README in lingua italiana (README.it.md)**](README.it.md)

---

### ⬇️ Download Pre-built App (No Python Required)

| Platform | Supported Hardware | Package Format | Download Link |
| :--- | :--- | :--- | :--- |
| **🍏 macOS** | Apple Silicon (M1 / M2 / M3 / M4 / M5) — macOS 26.0 Tahoe+ | Standalone Bundle (`.zip`) | [**Download Whisper Studio v3.0.5 (.zip)**](https://github.com/Ritolino/WhisperStudio/releases/download/v3.0.5/Whisper-Studio-v3.0.5-macOS.zip) |
| **🪟 Windows** | Windows 10 / 11 (64-bit) — NVIDIA RTX/GTX or Intel/AMD CPU | Standalone Portable (`.zip`) | [**Download Whisper Studio v3.0.5 (.zip)**](https://github.com/Ritolino/WhisperStudio/releases/download/v3.0.5/Whisper-Studio-v3.0.5-Windows.zip) |

*Simply download the `.zip` for your platform, extract it, and run immediately — zero Python or CUDA Toolkit installation required.*

> [!NOTE]
> **First Launch (Gatekeeper on macOS & SmartScreen on Windows):**
> - **macOS:** Whisper Studio uses an ad-hoc local signature (`codesign -s -`) rather than a paid Apple Developer notarization certificate. Drag `Whisper Studio.app` into **`/Applications`**, try opening it once → **Done**, then allow it in **System Settings → Privacy & Security → Open Anyway** (or run `xattr -dr com.apple.quarantine "/Applications/Whisper Studio.app" && open "/Applications/Whisper Studio.app"`).
> - **Windows:** Because `WhisperStudio.exe` is an open-source PyInstaller standalone bundle without a paid EV signing certificate, Windows SmartScreen or antivirus heuristics may prompt on first run (*Unknown Publisher*). You can audit or compile the full source directly from this repository.

---

## ✨ Features

- **🔒 100% Local Processing, Zero Telemetry & Privacy First**:
  - All audio/video decoding and Whisper neural inference run strictly on your own machine. No recordings or transcripts are ever uploaded to external servers.
  - Network access is strictly limited to first-time Whisper model downloads from Hugging Face and optional, non-blocking update checks via GitHub Releases REST API (`api.github.com`, 24-hour rate limit, toggleable in `Settings`).
- **⚡ Zero Hallucinations, Anti-Repetition & Maximum Hardware Throughput**:
  - Enforces `condition_on_previous_text=False`, `hallucination_silence_threshold=2.0`, and consecutive short-segment deduplication (`<= 3` normalized words) on both platforms — plus Silero VAD, `repetition_penalty=1.1`, and `no_repeat_ngram_size=4` on Windows — to prevent silence loops and end-of-recording repetitions on both **Large-v3** and **Large-v3 Turbo**.
  - Dedicated **Download Model**, **Pause Download** (preserves `.incomplete` / `.part` cache for resumable transfers), and **Cancel Download** controls work even when the queue is empty, displaying decimal `MB/s` telemetry.
- **🚀 Native Platform Architectures**:
  - **macOS (`v3.0.5` Native Rewrite)**: Pure Swift 6 (`SwiftUI` + `AppKit`) application targeting macOS 26.0+ Tahoe (`arm64`), paired over `stdin`/`stdout` JSON Lines with an isolated Python 3.12 Apple MLX helper (`WhisperEngine`), native `NSTouchBar` controls, and Activity Monitor **Formula A** memory pressure telemetry (`SystemMemoryService`).
  - **Windows**: PyQt6 + Faster-Whisper (`CTranslate2`) portable bundle (`WhisperStudio.exe`) with Python 3.12 (64-bit), preloaded NVIDIA CUDA 12 / cuDNN 9 libraries (`float16`), automatic multithreaded CPU fallback (`INT8`), cached `nvml.dll` VRAM telemetry, and pure-Qt internal drag-and-drop with live mouse-wheel scrolling.
- **🧠 Smart Hardware-Aware Memory Management**:
  - **Automatic Mode**: Selects **Large-v3 Standard** on high-memory systems (**≥ 24 GB** unified RAM on Apple Silicon; NVIDIA GPU with **≥ 6 GB** VRAM on Windows) and defaults lighter machines (including 8 GB and 16 GB Macs) to **Large-v3 Turbo** for lower memory pressure and ~2× throughput.
  - **Manual Mode & Persistent Memory**: Freely switch between **Large-v3 Standard** and **Large-v3 Turbo**. Preferences are persisted natively (`UserDefaults` on macOS, `QSettings` on Windows), and all weights are immediately unloaded (`mx.clear_cache()` / `gc.collect()`) when the batch finishes or stops.
- **📄 Dual Export, Mutual Format Guard & Smart Naming**:
  - Simultaneous `.txt` and Microsoft Word (`.docx`) export beside source files, into a custom folder, or via per-batch prompt, with progressive collision numbering `(2)`, `(3)` and a mutual guard ensuring at least one export format stays active.
  - Preserves custom user titles (e.g. `EGI 12 novembre.m4a` ➔ `Trascrizione EGI 12 novembre.docx`) while formatting generic smartphone recorder timestamps into `Trascrizione DD-MM-YY - HH.MM`.
- **🌐 Live Bilingual UI (🇮🇹 Italiano & 🇬🇧 English)** & **📂 Drag-and-Drop Live Queue**:
  - Automatic OS locale detection with instant menu-bar switching, recursive folder drop (14 audio/video formats including `.aiff`), and live reordering of pending items mid-batch.

---

## 🆕 What's New in v3.0.5

- **Complete Native macOS SwiftUI + AppKit Rewrite**: Replaced the legacy PyQt6 GUI, `libtouchbar.dylib`, and `Unlock_Whisper.command` on macOS 26.0 Tahoe (`arm64`) with a native Swift 6 interface (`macOS/App/`), native `NSTouchBar`, and an isolated Python 3.12 `WhisperEngine` JSON Lines helper (`mlx 0.32.4` / `mlx-whisper 0.4.3`), cutting out Qt runtime bloat and isolating neural execution (`multiprocessing.freeze_support()`, persistent logs in `~/Library/Logs/WhisperStudio/engine.log`).
- **Unified "Apple Squircle Concentrico" Design System (macOS & Windows)**: Harmonized both editions around a flat zinc palette (`#121214` / `#18181b`), concentric squircle geometry (`12pt` / `10pt` / `7pt`), animated 2-way capsule switches (`Model Mode`, `Audio Language`), grouped `.docx`/`.txt` switch card with mutual guard, `FlatProgressBar` capsules, and a single contextual primary button at rest (`Start` or `Download Model`).
- **Standalone Resumable Model Downloads**: Pre-download models even with an empty queue, featuring real **Pause** (preserves `.incomplete` / `.part` cache), **Cancel** (cleans partial cache), and decimal `MB/s` speed readout.
- **Anti-Repetition & Anti-Hallucination Upgrades**: Added `hallucination_silence_threshold=2.0` and consecutive short-segment deduplication (`<= 3` words) on both macOS and Windows, plus `repetition_penalty=1.1` and `no_repeat_ngram_size=4` on Windows.
- **24 GB Automatic Threshold & Formula A RAM Telemetry (macOS)**: Raised automatic **Large-v3 Standard** selection to `≥ 24 GB` unified RAM (defaulting 8 GB and 16 GB Macs to **Large-v3 Turbo**) with Activity Monitor Formula A Memory Pressure reporting and `SIGSTOP`/`SIGCONT` real pause with pause-subtracted ETA.
- **Windows Executable Alignment, Pure-Qt Drag & AV Hardening**: Renamed `WhisperPortable` ➔ `WhisperStudio.exe`, upgraded to Python 3.12 + CUDA 12 / cuDNN 9, replaced `QDrag.exec()` with pure-Qt ghost drag-and-drop supporting mouse-wheel scrolling and edge auto-scroll, cached `nvml.dll`, and suspended background polling/update checks during active model downloads.

*For the full release history, see [`CHANGELOG.md`](CHANGELOG.md), [`macOS/docs/CHANGELOG.md`](macOS/docs/CHANGELOG.md), and [`Windows/docs/CHANGELOG.md`](Windows/docs/CHANGELOG.md).*

---

## 📊 Whisper Studio vs. Other Transcription Workflows

| Feature / Metric | 🍏🪟 **Whisper Studio** | **OpenAI Whisper CLI (PyTorch)** | **Cloud Transcription SaaS** |
| :--- | :--- | :--- | :--- |
| **Audio & Transcript Privacy** | **100% Local on device** *(0 bytes uploaded)* | 100% Local on device | Uploaded to third-party servers |
| **Subscription / Usage Cost** | **Free & Open Source (\$0)** | Free (CLI only) | Paid per-minute / monthly subscription |
| **Runtime & Acceleration** | **Native SwiftUI + Apple MLX (Mac)** / **PyQt6 + CTranslate2 CUDA 12 (Win)** | Heavy PyTorch stack *(> 3 GB libs)* | Cloud-only *(requires internet)* |
| **Measured `large-v3-turbo` Disk / RSS** | **`~1.5–1.6 GB` weights** *(`~1.80 GiB` RSS in local benchmark)* | PyTorch FP32/FP16 stack *(significantly heavier CPU/RAM footprint)* | N/A (remote server) |
| **Hallucination & Silence Protection** | **Built-in** (`condition_on_previous_text=False`, threshold `2.0`, short-loop dedup + Silero VAD/penalties on Win) | Manual flags / no GUI dedup | Server-side black box |
| **GUI, Touch Bar & Live Queue** | **Native GUI, live drag-reorder, Pause/Resume & ETA** | Command-line terminal only | Web browser portal |
| **Export Formats & Naming** | **Simultaneous `.docx` + `.txt`, smart naming & collision numbering** | Raw terminal / text dumps | Manual web export |

---

## 🎧 Supported Audio & Video Formats

Supported out of the box via bundled FFmpeg (`macOS`) and PyAV (`Windows`):
- **Audio**: `MP3`, `WAV`, `M4A`, `AAC`, `FLAC`, `OGG`, `OPUS`, `ALAC`, `AIFF`, `WMA`
- **Video**: `MP4`, `MOV`, `MKV`, `WEBM`, `AVI`

---

## 🛠 System Requirements

| Specification | macOS Edition | Windows Edition |
| :--- | :--- | :--- |
| **Operating System** | macOS 26.0 (Tahoe) or newer | Windows 10 (64-bit) or Windows 11 (64-bit) |
| **Processor / GPU** | Apple Silicon (`arm64` — M1 / M2 / M3 / M4 / M5) | NVIDIA GeForce RTX / GTX (CUDA 12) or 64-bit Intel/AMD CPU |
| **RAM** | Minimum 8 GB (`Turbo` auto under 24 GB; `Large-v3` auto ≥ 24 GB) | Minimum 8 GB (NVIDIA GPU ≥ 6 GB VRAM for `Large-v3` auto) |
| **Permissions & Disk** | Standard user permissions (`No sudo`) • ~1.5–3.1 GB per cached model | Standard user permissions (portable) • ~1.6–3.1 GB per cached model |

---

## 💡 Frequently Asked Questions (FAQ)

### What makes Whisper Studio different from cloud transcription services or CLI Whisper?
Cloud services require uploading private lectures, meetings, or interviews to third-party servers and charge ongoing fees. Command-line Whisper tools require Python setup and lack visual progress, live queue reordering, `.docx` export, or anti-repetition guards. Whisper Studio gives you hardware-accelerated local inference (`Apple MLX` on Mac, `CTranslate2 CUDA 12` on Windows) in a polished native GUI with zero cloud uploads.

### Why does macOS Automatic Mode pick Large-v3 Turbo on 8 GB and 16 GB Macs?
In local benchmarks on real multi-speaker recordings, `Large-v3 Turbo` (`~1.5 GB`) runs at roughly 2× the speed of `Large-v3 Standard` (`~3.1 GB`) while matching transcription fidelity and leaving ample headroom in Apple Silicon's shared unified memory. Macs with **24 GB+ RAM** default to `Large-v3 Standard`, and you can still select `Large-v3 Standard` manually at any time.

### Does Whisper Studio send any audio or text over the internet?
Never. Audio decoding, neural transcription, and `.txt`/`.docx` generation happen completely locally on your computer. Internet access is only used when downloading a Whisper model from Hugging Face for the first time, or during the optional asynchronous check for new releases on GitHub (`Settings`).

### Why do macOS Gatekeeper or Windows SmartScreen warn on first launch?
Whisper Studio is a free, open-source project distributed without a paid Apple Developer notarization certificate or a commercial Windows EV code signing certificate. On macOS, drag `Whisper Studio.app` to `/Applications` and allow it once under **System Settings → Privacy & Security → Open Anyway** (or run `xattr -dr com.apple.quarantine "/Applications/Whisper Studio.app"`). You can also inspect and compile all source files directly from this repository.

---

## 🚀 Running & Building from Source

### For macOS (`macOS 26.0+`, Apple Silicon `arm64`)
Requires Swift 6 (`swiftc`), Python 3.12 (`arm64`), and an `arm64` `ffmpeg` binary placed at `macOS/ffmpeg` (e.g. `brew install ffmpeg && cp "$(which ffmpeg)" macOS/ffmpeg`):

```bash
cd macOS
python3 -m venv Engine/.venv
Engine/.venv/bin/pip install -r Engine/requirements-engine.txt
./Scripts/build_and_install_app.sh
```
The compiled and ad-hoc signed bundle is installed directly to `/Applications/Whisper Studio.app`.

### For Windows (`Windows 10/11 x64`, Python 3.12)
Run directly from source or package into `dist/WhisperStudio/` (`WhisperStudio.exe` + `_internal/`):

```powershell
cd Windows
python -m pip install -r requirements.txt
python whisper_studio.py

# Optional: build standalone portable bundle
python -m PyInstaller --clean -y WhisperStudio.spec
```

---

## 📁 Repository Structure

```text
WhisperStudio/
├── README.md                     # Master English presentation
├── README.it.md                  # Master Italian presentation
├── CHANGELOG.md                  # Cross-platform Keep a Changelog summary
├── LICENSE                       # MIT License
├── .gitignore                    # Excludes binaries (.app, .exe, _internal, ffmpeg, models/)
│
├── assets/                       # Shared brand icons and graphics
│   ├── wispr.png
│   ├── app_icon_black.png
│   ├── wispr.ico
│   └── AppIcon.icns
│
├── macOS/                        # macOS Edition (Native SwiftUI/AppKit + Apple MLX Helper)
│   ├── README.md / README.it.md
│   ├── App/                      # Native Swift 6 package (SwiftUI + AppKit + NSTouchBar)
│   ├── Engine/                   # Isolated Python 3.12 MLX JSONL helper & PyInstaller spec
│   ├── Scripts/                  # Build, inside-out codesign & /Applications installer
│   └── docs/                     # CHANGELOG, DECISIONS, ARCHITECTURE, DESIGN_SYSTEM, BUGS_AND_RISKS
│
└── Windows/                      # Windows Edition (PyQt6 + Faster-Whisper CUDA 12 / CPU)
    ├── README.md / README.it.md
    ├── whisper_studio.py         # Application source
    ├── WhisperStudio.spec        # PyInstaller standalone spec
    ├── requirements.txt          # Python 3.12 + CUDA 12 / cuDNN 9 dependencies
    ├── ISTRUZIONI.txt / INSTRUCTIONS.txt
    └── docs/                     # CHANGELOG, DECISIONS, ARCHITECTURE, BUGS_AND_RISKS
```

---

## 💡 About this Project & Disclaimer

This project was conceived, designed, and tested by **Gabriele Clemente ([@Ritolino](https://github.com/Ritolino))**.

> **Full Disclosure:** I am not a professional software engineer or UI/UX designer — I'm a passionate tech enthusiast! This application was architected, written, and refined through human-AI pair programming using **Google Antigravity** powered by **Gemini 3.8**.
>
> My primary contribution has been the initial concept, iterative testing, UI/UX design, feature scoping, and real-world verification on both Apple Silicon and Windows hardware (including Metal MLX acceleration, native `NSTouchBar`, NVIDIA CUDA 12 acceleration, CPU fallback, and complete bilingual localization).
>
> Because of this, suggestions, code reviews, and Pull Requests to improve the codebase, optimize dependencies, or enhance software architecture are warmly welcomed and appreciated!

---

### ⚖️ Legal & Acknowledgements

- **OpenAI Whisper**: Speech recognition models created by OpenAI, licensed under the MIT License.
- **Apple MLX**: High-performance machine learning framework developed for Apple Silicon.
- **Faster-Whisper & CTranslate2**: Fast inference engine developed by SYSTRAN, licensed under the MIT License.
- **PyAV & FFmpeg**: Multimedia processing handled by PyAV and FFmpeg libraries.
- All product names, logos, and brands are property of their respective owners.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
