# Changelog

All notable cross-platform changes to **Whisper Studio** are documented in this file.  
For full low-level engineering notes and bug reports, see [`macOS/docs/CHANGELOG.md`](macOS/docs/CHANGELOG.md) and [`Windows/docs/CHANGELOG.md`](Windows/docs/CHANGELOG.md).

---

## [3.0.5] — 2026-11-16 (Unified Apple Squircle Concentrico & Native macOS SwiftUI Rewrite)

### Added & Changed (Cross-Platform)
- **Unified "Apple Squircle Concentrico" Design System**: Aligned both macOS and Windows under a flat zinc dark palette (`#121214` / `#18181b` / `#1f1f23`) with concentric geometry (`12pt` cards, `10pt` controls, `7pt` inner indicators), `FlatProgressBar` capsules (`6pt` in RAM/rows, `10pt` dock), and a single contextual primary action button at rest (`Start Transcription` or `Download Model`), revealing `Pause` and `Cancel` only during active operations.
- **Dedicated Model Download Controls**: Pre-download model weights even with an empty queue, featuring **Pause download** (preserves `.incomplete` / `.part` files for resumable transfers), **Cancel download** (cleans partial cache), and decimal `MB/s` speed telemetry.
- **Animated 2-Way Segmented Capsule Switches**: Unified 2-way capsule switches for Engine Mode (**Automatic | Manual**) and Audio Language (**Italian/English | Auto-Detect**).
- **Export Format Mutual Guard**: Grouped `.docx` / `.txt` toggle card preventing both export formats from being disabled simultaneously.
- **Anti-Repetition & Anti-Hallucination Filters**: Added `hallucination_silence_threshold=2.0` and consecutive short-segment deduplication (`<= 3` words) on both macOS and Windows, plus `repetition_penalty=1.1` and `no_repeat_ngram_size=4` on Windows for cleaner **Turbo** and **Large-v3** transcripts.
- **Live Queue Reordering & Automatic 0% Reset**: Drag-and-drop reordering of pending items (even while another file is transcribing) and automatic progress bar/timer reset to `0%` (*Ready*) when emptying the queue.

### macOS Edition
- **Complete Native Swift 6 (`SwiftUI` + `AppKit`) Rewrite for macOS 26.0+ Tahoe (`arm64`)**: Replaced the legacy PyQt6 GUI, `touchbar.m`, `libtouchbar.dylib`, and `Unlock_Whisper.command` with a native SwiftPM app (`macOS/App/`) and native `NSTouchBar` controller (`TouchBarController`).
- **Isolated `WhisperEngine` Helper (Python 3.12.16 `arm64`, `stdin`/`stdout` JSON Lines)**: Extracted Apple MLX inference into a headless `--onedir` helper (`Contents/Resources/WhisperEngine/`) using `mlx 0.32.4`, `mlx-whisper 0.4.3`, and `huggingface_hub 2.4.0`, with `--probe`, `--check-cache`, `download_model`, `_AbortableTqdm`, `multiprocessing.freeze_support()`, persistent logs in `~/Library/Logs/WhisperStudio/engine.log`, atomic `.txt`/`.docx` writes, and real `SIGSTOP`/`SIGCONT` pause with exact ETA pause subtraction.
- **24 GB Automatic Mode Threshold & Formula A RAM Meter**: Raised the Automatic Mode threshold for **Large-v3 Standard** to `≥ 24 GB` unified RAM (defaulting 8 GB and 16 GB Macs to **Large-v3 Turbo**, while keeping `Large-v3` available in Manual Mode) paired with Activity Monitor Formula A Memory Pressure telemetry (`SystemMemoryService`).
- **Build & Inside-Out Signing Pipeline**: Added `macOS/Scripts/build_and_install_app.sh` to build `WhisperEngine` + SwiftPM `arm64` release, codesign inside-out, and install directly to `/Applications/Whisper Studio.app`.

### Windows Edition
- **Executable & Build Alignment (`WhisperStudio.exe`, Python 3.12 64-bit, CUDA 12 / cuDNN 9)**: Renamed standalone binary and PyInstaller spec from `WhisperPortable` to `WhisperStudio` and rebuilt in an isolated Python 3.12.10 `x64` environment (`PyQt6 6.12.1`, `faster-whisper 1.2.1`, `ctranslate2 4.9.0`, `nvidia-cublas-cu12`, `nvidia-cuda-nvrtc-cu12`, `nvidia-cudnn-cu12`).
- **Pure-Qt Internal Drag & Drop with Live Mouse-Wheel Scrolling (`BUG-03` / `DEC-015`)**: Replaced `QDrag.exec()` (OLE modal loop) with pure-Qt ghost-card dragging (`QueueItemCard` + `QueueListWidget`), live mouse-wheel scrolling during drag, and smooth edge auto-scrolling without any Win32 hooks.
- **Antivirus Behavioral Hardening (`R-WIN-03`)**: Cached `nvml.dll` handle instead of reloading every 2.5s, removed `SetWindowsHookExW`, and suspended RAM/VRAM polling timers and GitHub update checks during active `ModelDownloadWorker` downloads.

---

## [2.7.5] — 2026-10-12 (Liquid Glass & Destination Settings)
- Added native `Settings` menu with `Save transcriptions to ▸` (`beside original`, `custom folder...`, `ask every time`), automatic update check toggle, and engine-mode memory toggle.
- Added collision-safe progressive output numbering `(2)`, `(3)` synchronized across `.txt` and `.docx`.
- Added asynchronous non-blocking GitHub Releases update checker (24h rate-limit, 24h snooze, skip version, HTML-escaped release notes, platform asset filtering).
- Added smart file naming preserving custom user titles (e.g., `EGI 12 novembre.m4a`) while formatting generic recorder timestamps (`Trascrizione gg-mm-aa - oo.mm`).
- Added live bilingual UI (`Italian 🇮🇹` / `English 🇬🇧`), recursive folder drag & drop, `.aiff` support, pause-corrected ETA math, and full memory reclaim on completion/cancel.

---

## [2.7.0] — 2026-10-08
- macOS Touch Bar hardware support and dynamic Large-v3 / Turbo hardware detection.
- Windows cuBLAS 12 dynamic DLL preloading (`float16` GPU / `INT8` CPU fallback) and `.docx` file-lock protection.

---

## [2.0.0] — 2026-10-07
- Initial cross-platform architecture with Apple Silicon MLX (`macOS`) and Faster-Whisper CTranslate2 (`Windows`).
