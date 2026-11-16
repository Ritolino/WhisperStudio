<p align="center">
  <img src="assets/wispr.png" width="128" height="128" alt="Whisper Studio App Icon">
</p>

# Whisper Studio

[![Piattaforme](https://img.shields.io/badge/Piattaforme-macOS%20%7C%20Windows-blue?logo=apple&logoColor=white)](https://github.com/Ritolino/WhisperStudio)
[![Motore macOS](https://img.shields.io/badge/macOS-SwiftUI%20%2B%20Apple%20MLX-purple?logo=apple)](https://github.com/ml-explore/mlx-examples/tree/main/whisper)
[![Motore Windows](https://img.shields.io/badge/Windows-PyQt6%20%2B%20CUDA%20%2F%20CPU-brightgreen?logo=nvidia)](https://developer.nvidia.com/cuda-toolkit)
[![Release macOS](https://img.shields.io/badge/Release%20macOS-v3.0.5-orange)](https://github.com/Ritolino/WhisperStudio/releases/tag/v3.0.5)
[![Release Windows](https://img.shields.io/badge/Release%20Windows-v3.0.5-orange)](https://github.com/Ritolino/WhisperStudio/releases/tag/v3.0.5)
[![Licenza](https://img.shields.io/badge/Licenza-MIT-brightgreen.svg)](LICENSE)

Un'applicazione desktop nativa, **privacy-first e con esecuzione 100% locale** per la trascrizione audio e video su **macOS** (Swift 6 nativo / SwiftUI + Apple Silicon MLX) e **Windows** (PyQt6 + NVIDIA CUDA 12 / CPU `INT8`). Progettata come alternativa gratuita, senza abbonamenti e senza telemetria ai servizi cloud e ai pesanti wrapper PyTorch, con esportazione simultanea in **Testo Semplice (`.txt`)** e **Microsoft Word (`.docx`)**.

[**🇬🇧 Read the README in English (README.md)**](README.md)

---

### ⬇️ Download Applicazione Pre-compilata (Nessun Python Richiesto)

| Piattaforma | Hardware Supportato | Formato Pacchetto | Link per il Download |
| :--- | :--- | :--- | :--- |
| **🍏 macOS** | Apple Silicon (M1 / M2 / M3 / M4 / M5) — macOS 26.0 Tahoe+ | Bundle Standalone (`.zip`) | [**Scarica Whisper Studio v3.0.5 (.zip)**](https://github.com/Ritolino/WhisperStudio/releases/download/v3.0.5/Whisper-Studio-v3.0.5-macOS.zip) |
| **🪟 Windows** | Windows 10 / 11 (64-bit) — NVIDIA RTX/GTX o CPU Intel/AMD | Pacchetto Portatile (`.zip`) | [**Scarica Whisper Studio v3.0.5 (.zip)**](https://github.com/Ritolino/WhisperStudio/releases/download/v3.0.5/Whisper-Studio-v3.0.5-Windows.zip) |

*È sufficiente scaricare il file `.zip` per il proprio sistema, estrarlo e avviare l'app immediatamente — nessuna installazione manuale di Python o CUDA Toolkit richiesta.*

> [!NOTE]
> **Primo Avvio (Gatekeeper su macOS & SmartScreen su Windows):**
> - **macOS:** Whisper Studio utilizza una firma locale gratuita *ad-hoc* (`codesign -s -`) anziché un certificato Apple Developer a pagamento. Trascina `Whisper Studio.app` in **`/Applications`**, prova ad aprirla una volta → **Fine**, poi autorizzala in **Impostazioni di Sistema → Privacy e Sicurezza → Apri comunque** (oppure esegui da Terminale: `xattr -dr com.apple.quarantine "/Applications/Whisper Studio.app" && open "/Applications/Whisper Studio.app"`).
> - **Windows:** Poiché `WhisperStudio.exe` è un eseguibile open-source PyInstaller senza certificato EV commerciale, Windows SmartScreen o l'antivirus possono mostrare un avviso al primo avvio (*Editore sconosciuto*). Tutto il codice sorgente è aperto e verificabile in questo repository.

---

## ✨ Caratteristiche Principali

- **🔒 Elaborazione 100% Locale, Zero Telemetria & Privacy Totale**:
  - Tutta la decodifica audio/video e l'inferenza neurale Whisper avvengono esclusivamente sul tuo computer. Nessun file audio o testo trascritto lascia mai la macchina.
  - La rete viene utilizzata solo al primo scaricamento dei pesi Whisper da Hugging Face e per il controllo facoltativo e non bloccante degli aggiornamenti via GitHub Releases REST API (`api.github.com`, limite 24 ore, disattivabile da `Impostazioni`).
- **⚡ Zero Allucinazioni, Anti-Ripetizione & Massime Prestazioni Hardware**:
  - Configurato con `condition_on_previous_text=False`, `hallucination_silence_threshold=2.0` e deduplica dei segmenti brevi consecutivi identici (`<= 3` parole) su entrambe le piattaforme — più Silero VAD, `repetition_penalty=1.1` e `no_repeat_ngram_size=4` su Windows — per eliminare i loop nei silenzi e le ripetizioni finali sia su **Large-v3** che su **Large-v3 Turbo**.
  - Controlli dedicati **Scarica modello**, **Pausa download** (mantiene `.incomplete` / `.part` per la ripresa) e **Annulla download** utilizzabili anche a coda vuota, con telemetria di velocità in `MB/s` decimali.
- **🚀 Architetture Native per Piattaforma**:
  - **macOS (`v3.0.5` Riscrittura Nativa)**: Applicazione pura Swift 6 (`SwiftUI` + `AppKit`) per macOS 26.0+ Tahoe (`arm64`), collegata via JSON Lines (`stdin`/`stdout`) al processo helper isolato Python 3.12 Apple MLX (`WhisperEngine`), controlli nativi `NSTouchBar` e telemetria memoria allineata alla **Formula A** di Monitoraggio Attività (`SystemMemoryService`).
  - **Windows**: Bundle portatile PyQt6 + Faster-Whisper (`CTranslate2`) su Python 3.12 (64-bit) con librerie NVIDIA CUDA 12 / cuDNN 9 precaricate (`float16`), fallback automatico multithread su CPU (`INT8`), caching `nvml.dll` per la VRAM e riordino drag-and-drop puro Qt con scroll live via rotellina del mouse.
- **🧠 Gestione Intelligente della Memoria**:
  - **Modalità Automatica**: Seleziona **Large-v3 Standard** su configurazioni ad alta memoria (**≥ 24 GB** di RAM unificata su Apple Silicon; GPU NVIDIA con **≥ 6 GB** VRAM su Windows) e imposta **Large-v3 Turbo** sulle macchine più leggere (inclusi Mac da 8 GB e 16 GB) per dimezzare i tempi mantenendo la massima fluidità.
  - **Modalità Manuale & Persistenza**: Scelta libera tra **Large-v3 Standard** e **Large-v3 Turbo**, preferenze salvate nativamente (`UserDefaults` su macOS, `QSettings` su Windows) e rilascio immediato di RAM/VRAM (`mx.clear_cache()` / `gc.collect()`) al termine o arresto del batch.
- **📄 Doppia Esportazione, Vincolo Mutuo & Denominazione Intelligente**:
  - Esportazione simultanea `.txt` e `.docx` accanto al file sorgente, in cartella personalizzata oppure con richiesta a ogni avvio, con protezione anti-collisione `(2)`, `(3)` e vincolo mutuo che mantiene sempre almeno un formato attivo.
  - Preserva i titoli personalizzati (es. `EGI 12 novembre.m4a` ➔ `Trascrizione EGI 12 novembre.docx`) formattando invece i timestamp generici in `Trascrizione GG-MM-AA - OO.MM`.
- **🌐 Interfaccia Bilingue Live (🇮🇹 Italiano & 🇬🇧 English)** & **📂 Coda Drag & Drop**:
  - Rilevamento automatico della lingua OS, cambio immediato dal menu superiore, importazione ricorsiva di file e cartelle (14 formati audio/video incluso `.aiff`) e riordino live dei file in attesa anche durante la trascrizione.

---

## 🆕 Novità della v3.0.5

- **Riscrittura Nativa macOS in SwiftUI + AppKit**: Sostituiti su macOS 26.0 Tahoe (`arm64`) la vecchia GUI PyQt6, `libtouchbar.dylib` e `Unlock_Whisper.command` con un'app nativa Swift 6 (`macOS/App/`), `NSTouchBar` nativa e helper isolato Python 3.12 `WhisperEngine` su JSON Lines (`mlx 0.32.4` / `mlx-whisper 0.4.3`), con `multiprocessing.freeze_support()` e log persistenti in `~/Library/Logs/WhisperStudio/engine.log`.
- **Design System Unificato "Apple Squircle Concentrico" (macOS & Windows)**: Uniformate entrambe le edizioni con palette Zinc scura (`#121214` / `#18181b`), raggi concentrici (`12pt` / `10pt` / `7pt`), switch animati a capsula a 2 vie (`Modello` e `Lingua Audio`), card raggruppata `.docx`/`.txt` con vincolo mutuo, barre flat (`FlatProgressBar`) e un solo pulsante contestuale a riposo (`Avvia` o `Scarica modello`).
- **Download Modelli Indipendente & Riprendibile**: Pre-download dei modelli anche a coda vuota, con **Pausa** reale (mantiene la cache `.incomplete` / `.part`), **Annulla** (ripulisce i file parziali) e velocità decimale in `MB/s`.
- **Filtri Anti-Ripetizione & Anti-Allucinazione**: Introdotti `hallucination_silence_threshold=2.0` e deduplica dei segmenti brevi consecutivi (`<= 3` parole) su entrambe le piattaforme, più `repetition_penalty=1.1` e `no_repeat_ngram_size=4` su Windows.
- **Soglia Modalità Automatica a 24 GB & RAM Formula A (macOS)**: Alzata a `≥ 24 GB` di RAM unificata la soglia automatica per **Large-v3 Standard** (Mac da 8 GB e 16 GB su **Large-v3 Turbo** di default, con `Large-v3` sempre selezionabile in Manuale), barra Memory Pressure Formula A e pausa reale `SIGSTOP`/`SIGCONT` con sottrazione esatta del tempo in pausa.
- **Allineamento Eseguibile Windows, Drag Puro Qt & Hardening Antivirus**: Rinominato `WhisperPortable` ➔ `WhisperStudio.exe`, migrazione a Python 3.12 + CUDA 12 / cuDNN 9, sostituzione di `QDrag.exec()` con drag-and-drop puro Qt con rotellina mouse funzionante e auto-scroll ai bordi, caching `nvml.dll` e sospensione del polling durante i download attivi.

*Per la cronologia tecnica completa consulta [`CHANGELOG.md`](CHANGELOG.md), [`macOS/docs/CHANGELOG.md`](macOS/docs/CHANGELOG.md) e [`Windows/docs/CHANGELOG.md`](Windows/docs/CHANGELOG.md).*

---

## 📊 Whisper Studio a Confronto con le Alternative

| Caratteristica / Metrica | 🍏🪟 **Whisper Studio** | **OpenAI Whisper CLI (PyTorch)** | **Servizi Cloud di Trascrizione** |
| :--- | :--- | :--- | :--- |
| **Privacy Audio e Testi** | **100% Locale sul dispositivo** *(0 byte inviati)* | 100% Locale sul dispositivo | Caricamento su server di terze parti |
| **Costo / Abbonamento** | **Gratuito & Open Source (€0)** | Gratuito (solo CLI) | A consumo al minuto / abbonamento |
| **Runtime & Accelerazione** | **SwiftUI nativo + Apple MLX (Mac)** / **PyQt6 + CTranslate2 CUDA 12 (Win)** | Stack PyTorch pesante *(> 3 GB librerie)* | Solo Cloud *(richiede Internet)* |
| **Impronta Misurata `large-v3-turbo`** | **`~1.5–1.6 GB` pesi** *(`~1.80 GiB` RSS in test locale)* | Stack PyTorch FP32/FP16 *(impronta RAM/disco molto superiore)* | N/D (server remoto) |
| **Protezione Allucinazioni & Loop** | **Integrata** (`condition_on_previous_text=False`, soglia `2.0`, deduplica breve + Silero VAD/penalità su Win) | Flag manuali / nessuna deduplica UI | Scatola nera lato server |
| **Interfaccia, Touch Bar & Coda Live** | **GUI nativa, riordino live, Pausa/Riprendi & ETA** | Solo terminale a riga di comando | Portale web browser |
| **Esportazione & Nomi File** | **`.docx` + `.txt` simultanei, titoli preservati & anti-collisione** | Output testuale grezzo da terminale | Esportazione manuale dal browser |

---

## 🎧 Formati Audio e Video Supportati

Supportati nativamente tramite FFmpeg incluso (`macOS`) e PyAV (`Windows`):
- **Audio**: `MP3`, `WAV`, `M4A`, `AAC`, `FLAC`, `OGG`, `OPUS`, `ALAC`, `AIFF`, `WMA`
- **Video**: `MP4`, `MOV`, `MKV`, `WEBM`, `AVI`

---

## 🛠 Requisiti di Sistema

| Specifica | Edizione macOS | Edizione Windows |
| :--- | :--- | :--- |
| **Sistema Operativo** | macOS 26.0 (Tahoe) o successivo | Windows 10 (64-bit) o Windows 11 (64-bit) |
| **Processore / GPU** | Apple Silicon (`arm64` — M1 / M2 / M3 / M4 / M5) | GPU NVIDIA GeForce RTX / GTX (CUDA 12) o CPU Intel/AMD 64-bit |
| **RAM** | Minimo 8 GB (`Turbo` auto sotto 24 GB; `Large-v3` auto ≥ 24 GB) | Minimo 8 GB (GPU NVIDIA ≥ 6 GB VRAM per `Large-v3` auto) |
| **Permessi & Spazio Disco** | Normale account utente (`No sudo`) • ~1.5–3.1 GB per modello | Normale account utente (portatile) • ~1.6–3.1 GB per modello |

---

## 💡 Domande Frequenti (FAQ)

### Cosa differenzia Whisper Studio dai servizi cloud o da Whisper da riga di comando?
I servizi cloud richiedono di caricare lezioni, riunioni o interviste private su server esterni e prevedono costi al minuto. Gli strumenti CLI richiedono configurazioni Python manuali e non offrono coda drag-and-drop, stima ETA, pausa reale, esportazione `.docx` né filtri anti-ripetizione in post-processing. Whisper Studio racchiude inferenza accelerata su hardware locale (`Apple MLX` su Mac, `CTranslate2 CUDA 12` su Windows) in un'interfaccia desktop nativa.

### Perché su Mac da 8 GB e 16 GB la Modalità Automatica sceglie Large-v3 Turbo?
Nei benchmark reali su registrazioni multi-voce, `Large-v3 Turbo` (`~1.5 GB`) trascrive a velocità circa doppia rispetto a `Large-v3 Standard` (`~3.1 GB`) mantenendo una fedeltà acustica praticamente equivalente e lasciando margine ampio nella memoria unificata condivisa di Apple Silicon. I Mac con **24 GB+ RAM** usano invece `Large-v3 Standard` di default, mentre in Modalità Manuale è sempre possibile scegliere liberamente entrambi.

### Whisper Studio invia audio o testi su Internet?
Mai. Decodifica multimediale, inferenza neurale e creazione di `.txt`/`.docx` avvengono interamente in locale sul computer. La rete viene usata soltanto al primo download di un modello Whisper da Hugging Face e, se abilitato nelle impostazioni, per verificare la disponibilità di nuove versioni su GitHub Releases.

### Perché macOS Gatekeeper o Windows SmartScreen mostrano un avviso al primo avvio?
Whisper Studio è un progetto gratuito e open-source privo di un certificato commerciale a pagamento (Apple Developer Notarization o EV Code Signing Windows). Su macOS, sposta `Whisper Studio.app` in `/Applications` e autorizzala una volta in **Impostazioni di Sistema → Privacy e Sicurezza → Apri comunque** (oppure `xattr -dr com.apple.quarantine "/Applications/Whisper Studio.app"`). Tutto il codice sorgente è inoltre ispezionabile e compilabile da questo repository.

---

## 🚀 Esecuzione e Compilazione da Sorgente

### Per macOS (`macOS 26.0+`, Apple Silicon `arm64`)
Richiede Swift 6 (`swiftc`), Python 3.12 (`arm64`) e un binario `ffmpeg` `arm64` collocato in `macOS/ffmpeg` (es. `brew install ffmpeg && cp "$(which ffmpeg)" macOS/ffmpeg`):

```bash
cd macOS
python3 -m venv Engine/.venv
Engine/.venv/bin/pip install -r Engine/requirements-engine.txt
./Scripts/build_and_install_app.sh
```
Il bundle compilato e firmato viene installato direttamente in `/Applications/Whisper Studio.app`.

### Per Windows (`Windows 10/11 x64`, Python 3.12)
Avvia da codice sorgente o compila il pacchetto portatile in `dist/WhisperStudio/` (`WhisperStudio.exe` + `_internal/`):

```powershell
cd Windows
python -m pip install -r requirements.txt
python whisper_studio.py

# Opzionale: compilazione eseguibile portatile standalone
python -m PyInstaller --clean -y WhisperStudio.spec
```

---

## 📁 Struttura del Repository

```text
WhisperStudio/
├── README.md                     # Documentazione Master in lingua inglese
├── README.it.md                  # Documentazione Master in lingua italiana
├── CHANGELOG.md                  # Registro modifiche unificato (Keep a Changelog)
├── LICENSE                       # Licenza MIT
├── .gitignore                    # Esclude binari compilati (.app, .exe, _internal, ffmpeg, models/)
│
├── assets/                       # Icone e grafica condivisa del brand
│   ├── wispr.png
│   ├── app_icon_black.png
│   ├── wispr.ico
│   └── AppIcon.icns
│
├── macOS/                        # Edizione macOS (SwiftUI/AppKit Nativo + Apple MLX Helper)
│   ├── README.md / README.it.md
│   ├── App/                      # Pacchetto Swift 6 nativo (SwiftUI + AppKit + NSTouchBar)
│   ├── Engine/                   # Helper isolato Python 3.12 MLX JSONL e spec PyInstaller
│   ├── Scripts/                  # Script di build, firma inside-out e installazione /Applications
│   └── docs/                     # CHANGELOG, DECISIONS, ARCHITECTURE, DESIGN_SYSTEM, BUGS_AND_RISKS
│
└── Windows/                      # Edizione Windows (PyQt6 + Faster-Whisper CUDA 12 / CPU)
    ├── README.md / README.it.md
    ├── whisper_studio.py         # Codice sorgente applicativo
    ├── WhisperStudio.spec        # Specifica PyInstaller standalone
    ├── requirements.txt          # Dipendenze Python 3.12 + CUDA 12 / cuDNN 9
    ├── ISTRUZIONI.txt / INSTRUCTIONS.txt
    └── docs/                     # CHANGELOG, DECISIONS, ARCHITECTURE, BUGS_AND_RISKS
```

---

## 💡 Informazioni sul Progetto & Disclaimer

Questo progetto è stato ideato, progettato e collaudato da **Gabriele Clemente ([@Ritolino](https://github.com/Ritolino))**.

> **Trasparenza:** Non sono un ingegnere del software o un designer UI/UX professionista — sono un appassionato di tecnologia! Questa applicazione è stata architettata, scritta e rifinita attraverso pair programming uomo-AI utilizzando **Google Antigravity** potenziato da **Gemini 3.8**.
>
> Il mio contributo principale è stato l'ideazione del concetto iniziale, il testing iterativo, il design UI/UX, la definizione delle funzionalità e la validazione sul campo su hardware Apple Silicon e Windows (inclusa l'accelerazione Metal MLX, la `NSTouchBar` nativa, l'accelerazione NVIDIA CUDA 12, il fallback CPU e la localizzazione bilingue completa).
>
> Per questo motivo, suggerimenti, code review e Pull Request per migliorare il codice, ottimizzare le dipendenze o perfezionare l'architettura software sono calorosamente benvenuti e apprezzati!

---

### ⚖️ Note Legali e Riconoscimenti

- **OpenAI Whisper**: Modelli di riconoscimento vocale creati da OpenAI, distribuiti con licenza MIT.
- **Apple MLX**: Framework di machine learning ad alte prestazioni sviluppato per Apple Silicon.
- **Faster-Whisper & CTranslate2**: Motore di inferenza veloce sviluppato da SYSTRAN, distribuito con licenza MIT.
- **PyAV & FFmpeg**: Elaborazione multimediale gestita tramite librerie PyAV e FFmpeg.
- Tutti i nomi di prodotti, loghi e marchi appartengono ai rispettivi proprietari.

---

## 📄 Licenza

Il progetto è concesso in licenza secondo i termini della licenza MIT — consulta il file [LICENSE](LICENSE) per tutti i dettagli.
