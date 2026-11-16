# Whisper Studio (Windows Edition)

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%2F%2011%20(64--bit)-blue?logo=windows&logoColor=white)](https://github.com/Ritolino/WhisperStudio)
[![Engine](https://img.shields.io/badge/Engine-NVIDIA%20CUDA%20%2F%20CPU-green?logo=nvidia)](https://developer.nvidia.com/cuda-toolkit)
[![UI](https://img.shields.io/badge/UI-PyQt6%20Modern%20Dark-purple)](https://riverbankcomputing.com/software/pyqt/)
[![Release](https://img.shields.io/badge/Release-v3.0.5-orange)](https://github.com/Ritolino/WhisperStudio/releases/tag/v3.0.5)

A standalone, portable, 100% local audio and video transcription studio tailored for **Windows 10/11**, powered by Faster-Whisper (CTranslate2) with NVIDIA CUDA 12 GPU acceleration and multithreaded CPU fallback.

---

## ⚡ Highlights
- **100% Local & Private Transcription:** Your audio files and transcripts never leave your PC. Zero audio or text data sent to cloud servers (with optional, non-blocking GitHub release update checks).
- **Hardware Acceleration:** Automatic preloading of NVIDIA cuBLAS 12 libraries for `float16` GPU inference, with smooth fallback to multithreaded `INT8` on Intel/AMD CPUs.
- **Zero Hallucinations & Anti-Repetition:** Integrated Silero Voice Activity Detection (VAD), `condition_on_previous_text=False`, `repetition_penalty=1.1`, `no_repeat_ngram_size=4`, `hallucination_silence_threshold=2.0`, and consecutive short-segment deduplication for cleaner **Turbo** and **Large-v3** transcripts.
- **Portable & Ready-to-Run:** Pre-built distribution (`WhisperStudio.exe`) requires no Python or CUDA Toolkit installations.
- **Dual Export with File-Lock Protection:** Generates Plain Text (`.txt`) and Word (`.docx`) files beside original media, auto-incrementing filenames if Word has locked the file.
- **Smart Model Selector:** Selects **Large-v3 Standard** on high-end hardware (NVIDIA GPU with ≥6 GB VRAM) and switches to **Large-v3 Turbo** on lighter systems.
- **Dual-Language UI:** Live switching between **Italian 🇮🇹** and **English 🇬🇧** with crisp vector-rendered flag icons.
- **Smart File Naming:** Automatically preserves custom file titles (e.g. `EGI 12 novembre.m4a` ➔ `Trascrizione EGI 12 novembre.docx`) while formatting generic smartphone recorder timestamps into `Trascrizione gg-mm-aa - oo.mm`.

---

## 🚀 Running from Source
```bash
python -m pip install -r requirements.txt
python whisper_studio.py
```

## 📦 Building Standalone Executable
```bash
python -m PyInstaller --clean -y WhisperStudio.spec
```
The compiled standalone executable and `_internal` folder will be placed in `dist/WhisperStudio/`.
