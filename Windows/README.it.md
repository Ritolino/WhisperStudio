# Whisper Studio (Edizione Windows)

[![Piattaforma](https://img.shields.io/badge/Piattaforma-Windows%2010%20%2F%2011%20(64--bit)-blue?logo=windows&logoColor=white)](https://github.com/Ritolino/WhisperStudio)
[![Motore](https://img.shields.io/badge/Motore-NVIDIA%20CUDA%20%2F%20CPU-green?logo=nvidia)](https://developer.nvidia.com/cuda-toolkit)
[![Interfaccia](https://img.shields.io/badge/UI-PyQt6%20Modern%20Dark-purple)](https://riverbankcomputing.com/software/pyqt/)
[![Versione](https://img.shields.io/badge/Versione-v3.0.5-orange)](https://github.com/Ritolino/WhisperStudio/releases/tag/v3.0.5)

Applicazione di trascrizione audio e video standalone, portatile e con elaborazione 100% locale per **Windows 10/11**, basata sul motore Faster-Whisper (CTranslate2) con accelerazione GPU NVIDIA CUDA 12 e fallback multithread su CPU Intel/AMD.

---

## ⚡ Caratteristiche Principali
- **Trascrizione 100% Locale e Riservata:** Nessun file audio o testo trascritto viene mai inviato su server o cloud: tutto rimane rigorosamente sul tuo PC (con controllo aggiornamenti facoltativo e non bloccante via API di GitHub).
- **Accelerazione Hardware Ibrida:** Precaricamento automatico delle librerie dinamiche cuBLAS 12 per inferenza GPU in `float16`, con passaggio automatico a CPU multithreading in quantizzazione `INT8` se non è presente una scheda NVIDIA.
- **Zero Allucinazioni & Anti-Ripetizione:** Filtro Silero VAD, `condition_on_previous_text=False`, `repetition_penalty=1.1`, `no_repeat_ngram_size=4`, `hallucination_silence_threshold=2.0` e deduplica dei segmenti brevi consecutivi per trascrizioni più pulite su **Turbo** e **Large-v3**.
- **Portatile e Immediato:** La versione standalone (`WhisperStudio.exe`) non richiede né Python né il download manuale del CUDA Toolkit.
- **Doppia Esportazione con Protezione Blocco File:** File `.txt` e `.docx` salvati accanto ai file sorgente, con sistema di auto-incremento se il documento è aperto in Word.
- **Gestione Automatica Modelli:** Rileva la GPU e la memoria video (GPU NVIDIA con ≥6 GB VRAM: Large-v3 Standard; altri sistemi: Large-v3 Turbo).
- **Interfaccia Bilingue:** Selettore dinamico **Italiano 🇮🇹** e **Inglese 🇬🇧** con bandiere vettoriali nitide.
- **Denominazione Intelligente dei File:** Preserva intatti i titoli personalizzati (es. `EGI 12 novembre.m4a` ➔ `Trascrizione EGI 12 novembre.docx`) e pulisce automaticamente i nomi generici dei registratori vocali.

---

## 🚀 Esecuzione da Codice Sorgente
```bash
python -m pip install -r requirements.txt
python whisper_studio.py
```

## 📦 Compilazione Eseguibile Standalone
```bash
python -m PyInstaller --clean -y WhisperStudio.spec
```
L'eseguibile compilato e la cartella `_internal` saranno generati in `dist/WhisperStudio/`.
