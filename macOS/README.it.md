# Whisper Studio (Edizione macOS)

[![Piattaforma](https://img.shields.io/badge/Piattaforma-macOS%2026%2B%20(Apple%20Silicon)-blue?logo=apple&logoColor=white)](https://github.com/Ritolino/WhisperStudio)
[![Motore](https://img.shields.io/badge/Motore-Apple%20Silicon%20(MLX)-purple?logo=apple)](https://github.com/ml-explore/mlx-examples/tree/main/whisper)
[![Interfaccia](https://img.shields.io/badge/UI-SwiftUI%20%2B%20AppKit-purple?logo=swift)](https://developer.apple.com/xcode/swiftui/)
[![Versione](https://img.shields.io/badge/Versione-v3.0.5-orange)](https://github.com/Ritolino/WhisperStudio/releases/tag/v3.0.5)

Applicazione di trascrizione audio e video standalone, con elaborazione 100% locale e incentrata sulla privacy, ottimizzata specificamente per **Apple Silicon** (M1, M2, M3, M4, M5) su **macOS 26.0 Tahoe** o successivo, che abbina un'interfaccia **nativa SwiftUI + AppKit** a un motore isolato **Apple MLX Metal**.

---

## ⚡ Caratteristiche Principali
- **Elaborazione 100% Locale e Riservata:** I file audio e le trascrizioni generate vengono elaborati e salvati interamente sul Mac. La connessione Internet viene usata solo al primo download del modello Whisper da Hugging Face e per il controllo facoltativo degli aggiornamenti su GitHub.
- **Architettura Nativa macOS 26 Tahoe:** GUI pura in Swift 6 (`SwiftUI` + `AppKit`) che comunica via JSON Lines su stdin/stdout con il processo helper headless `WhisperEngine`.
- **Accelerazione Metal (Apple MLX):** Sfrutta la memoria unificata e i core grafici Metal con modelli `Large-v3 Standard` e `Large-v3 Turbo`.
- **Riduzione delle Ripetizioni:** Configurato con `condition_on_previous_text=False` per contenere i loop di ripetizione e i rallentamenti nei silenzi.
- **Supporto Touch Bar MacBook Pro:** Controlli nativi `NSTouchBar` con feedback di avanzamento hardware in tempo reale.
- **Doppia Esportazione & Destinazione Flessibile:** Generazione simultanea di file `.txt` e `.docx` accanto ai file originali, in una cartella personalizzata oppure con richiesta a ogni avvio.
- **Interfaccia Bilingue:** Passaggio immediato in tempo reale tra **Italiano 🇮🇹** e **Inglese 🇬🇧**.
- **Denominazione Intelligente dei File:** Preserva intatti i titoli personalizzati (es. `EGI 12 novembre.m4a` ➔ `Trascrizione EGI 12 novembre.docx`) e formatta automaticamente i nomi generici dei registratori vocali in `Trascrizione gg-mm-aa - oo.mm`.

---

## 🚀 Compilazione e Installazione `.app`
Requisiti: macOS 26.0+ (Apple Silicon `arm64`), Xcode / Swift Command Line Tools (`swift 6.x`), un binario `ffmpeg` `arm64` collocato in `macOS/ffmpeg` (es. `brew install ffmpeg && cp "$(which ffmpeg)" macOS/ffmpeg`) e Python 3.12 con le dipendenze in [`Engine/requirements-engine.txt`](Engine/requirements-engine.txt).

```bash
cd macOS
python3 -m pip install -r Engine/requirements-engine.txt
./Scripts/build_and_install_app.sh
```
Compila `WhisperEngine` (helper MLX PyInstaller `--onedir`), compila `WhisperStudio` con Swift Package Manager (`arm64` release), applica la firma inside-out e installa `/Applications/Whisper Studio.app`.

## 🛠️ Compilazione UI Nativa con SwiftPM (Sviluppo)
```bash
cd macOS/App
swift build -c release --arch arm64
```
