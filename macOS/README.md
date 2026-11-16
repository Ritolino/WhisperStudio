# Whisper Studio (macOS Edition)

[![Platform](https://img.shields.io/badge/Platform-macOS%2026%2B%20(Apple%20Silicon)-blue?logo=apple&logoColor=white)](https://github.com/Ritolino/WhisperStudio)
[![Engine](https://img.shields.io/badge/Engine-Apple%20Silicon%20(MLX)-purple?logo=apple)](https://github.com/ml-explore/mlx-examples/tree/main/whisper)
[![UI](https://img.shields.io/badge/UI-SwiftUI%20%2B%20AppKit-purple?logo=swift)](https://developer.apple.com/xcode/swiftui/)
[![Release](https://img.shields.io/badge/Release-v3.0.5-orange)](https://github.com/Ritolino/WhisperStudio/releases/tag/v3.0.5)

Standalone, 100% local, privacy-first audio and video transcription app tailored specifically for **Apple Silicon** (M1, M2, M3, M4, M5) on **macOS 26.0 Tahoe** or later, pairing a **native SwiftUI + AppKit** interface with an isolated **Apple MLX Metal** engine.

---

## ⚡ Highlights
- **100% Local Processing:** Audio files and generated transcripts are processed and saved entirely on your Mac. Internet is only used on first download of a Whisper model from Hugging Face and for optional non-blocking GitHub update checks.
- **Native macOS 26 Tahoe Architecture:** Pure Swift 6 (`SwiftUI` + `AppKit`) GUI communicating over stdin/stdout JSON Lines with an isolated headless `WhisperEngine` helper binary.
- **Metal Acceleration (Apple MLX):** Unified memory architecture with direct GPU inferencing (`Large-v3 Standard` and `Large-v3 Turbo`).
- **Reduced Repetition Loops:** Uses `condition_on_previous_text=False` to curb hallucination loops during silent intervals.
- **MacBook Pro Touch Bar:** Native `NSTouchBar` controls and live hardware progress readout.
- **Dual Export & Flexible Output:** Simultaneous `.txt` and `.docx` output saved beside source files, in a custom folder, or via a per-batch prompt.
- **Dual-Language UI:** Live switching between **Italian 🇮🇹** and **English 🇬🇧**.
- **Smart File Naming:** Preserves custom file titles (e.g. `EGI 12 novembre.m4a` ➔ `Trascrizione EGI 12 novembre.docx`) while formatting generic smartphone recorder timestamps into `Trascrizione gg-mm-aa - oo.mm`.

---

## 🚀 Building & Installing `.app`
Requirements: macOS 26.0+ (Apple Silicon `arm64`), Xcode / Swift Command Line Tools (`swift 6.x`), a static/local `ffmpeg` `arm64` binary placed at `macOS/ffmpeg` (e.g. via `brew install ffmpeg && cp "$(which ffmpeg)" macOS/ffmpeg`), and Python 3.12 with [`Engine/requirements-engine.txt`](Engine/requirements-engine.txt) dependencies.

```bash
cd macOS
python3 -m pip install -r Engine/requirements-engine.txt
./Scripts/build_and_install_app.sh
```
This compiles `WhisperEngine` (headless MLX PyInstaller `--onedir`), compiles `WhisperStudio` via Swift Package Manager (`arm64` release), signs inside-out, and installs `/Applications/Whisper Studio.app`.

## 🛠️ Running Native UI from SwiftPM (Development)
```bash
cd macOS/App
swift build -c release --arch arm64
```
