# Whisper MacOS — Registro Modifiche & Changelog

## [3.0.5] — Novembre 2026 (Native SwiftUI + MLX Helper Architecture)
### Riscrittura Architetturale Completa
- **Interfaccia Nativa Swift 6 (`SwiftUI` + `AppKit`) per macOS 26.0 Tahoe (`arm64`)**:
  - Sostituita integralmente la GUI PyQt6 e la libreria dinamica `libtouchbar.dylib` con un'applicazione nativa SwiftPM in [`macOS/App/`](../App/Package.swift).
  - Ridotta drasticamente l'impronta del runtime grafico eliminando Qt/PyQt6 dal bundle `.app`.
  - Tema scuro grigio zinco fisso ([`AppTheme.swift`](../App/Sources/Theme/AppTheme.swift): `#121214` / `#18181b` / `#1f1f23`) con Design System unificato **Apple Squircle Concentrico** ([`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md): card `12pt`, controlli/pulsanti `10pt`, cursori concentrici `7pt`), `AppleSegmentedSwitch` per Modello (`Automatica | Manuale`) e Lingua Audio, card raggruppata `AppleSwitchToggleStyle` ON/OFF per Formati di Esportazione (con vincolo di almeno un formato sempre attivo), sidebar snellita senza divisori intermedi ridondanti, `FlatProgressBar` unificata anche su RAM, alert nativi standard, pannello guida (`HelpGuideView`), log (`LogsSheetView`) e controlli nativi `NSTouchBar` in [`TouchBarController.swift`](../App/Sources/Services/TouchBarController.swift).
- **Motore Isolato `WhisperEngine` (`stdin`/`stdout` JSON Lines — Python 3.12 `arm64`)**:
  - Estratto il backend Python/MLX in [`macOS/Engine/whisper_engine.py`](../Engine/whisper_engine.py), migrato da Python 3.9.6 a **Python 3.12.16 (`arm64`)** tramite ambiente isolato `macOS/Engine/.venv` (`mlx 0.32.4`, `mlx-whisper 0.4.3`, `huggingface_hub 2.4.0`, `pyinstaller 6.22.3`), compilato come bundle headless `--onedir` ([`WhisperEngine.spec`](../Engine/WhisperEngine.spec)) e collocato in `Contents/Resources/WhisperEngine/`.
  - Comunicazione strutturata JSON Lines su `sys.__stdout__` / `sys.stdin` con logging diagnostico isolato su `sys.stderr`, modalità `--probe` per durata media e `--check-cache` / comando `download_model` per il download preventivo del modello anche a coda vuota, `condition_on_previous_text=False`, `hallucination_silence_threshold=2.0`, deduplica dei segmenti brevi consecutivi identici (`<= 3` parole, normalizzazione `t.lower().strip(".,!?;:…\"'()[]{}")`), `_AbortableTqdm` con `disable=False` (progresso, MB scaricati e velocità MB/s anche su pipe non-TTY) e scritture atomiche `.txt`/`.docx`.
- **Parità Funzionale v2.7.5 + Miglioramenti di Robustezza**:
  - Mantenuti integralmente selezione modello (`Large-v3 Standard`, `Large-v3 Turbo` + modalità automatica con soglia **≥ 24 GB RAM** per `Large-v3 Standard` e `Large-v3 Turbo` predefinito su Mac da 8 GB e 16 GB + barra Memory Pressure in tempo reale allineata a Activity Monitor / Pico Formula A), drag & drop ricorsivo di file e cartelle (`.aiff` incluso), riordino drag-and-drop in coda con indicatore tra le card e preview compatta (attivo anche sui file `.waiting` durante una trascrizione), icone SF Symbols per peso/durata/trascorso/rimanente, pulsante rimozione riga rosso su hover, reset automatico barra al 0% su svuotamento coda, logging persistente su `~/Library/Logs/WhisperStudio/engine.log`, protezione `multiprocessing.freeze_support()` + `var cmd` in `EngineProtocol`, denominazione intelligente anti-collisione `(2)`/`(3)` sincronizzata tra `.txt` e `.docx`, pausa reale (`SIGSTOP`/`SIGCONT` sul processo helper con sottrazione esatta del tempo in pausa per velocità/ETA), pulsanti **Scarica modello**, **Pausa download** (conserva cache `.incomplete` per riprendere) e **Annulla download** (pulisce i file parziali dalla cache) e finestra `UpdateDialogView` con rinvio 24h / ignora versione / verifica manuale.
  - Nuovo script [`Scripts/build_and_install_app.sh`](../Scripts/build_and_install_app.sh) con compilazione automatica engine + SwiftPM release `arm64`, assemblaggio bundle, firma inside-out e installazione in `/Applications/Whisper Studio.app`.

### Rimosso
- Rimossi i file obsoleti PyQt6 (`whisper_studio.py`, `Whisper Studio.spec`, `requirements.txt`, `touchbar.m`, `libtouchbar.dylib`, `Unlock_Whisper.command`).

---

## [2.7.5] — Novembre 2026 (Liquid Glass Edition)
### Aggiunto
- **Nuovo Menu Impostazioni Nativo macOS**:
  - Controllo toggle per il controllo automatico degli aggiornamenti (`auto_check_updates`).
  - Toggle facoltativo per memorizzare l'ultima modalità del motore e modello manuale (`remember_engine_mode`).
  - Gestione avanzata destinazione trascrizioni con 3 opzioni mutuamente esclusive:
    - *Accanto al file originale* (`source`)
    - *Cartella personalizzata…* (`custom`, con percorso mostrato in riga secondaria e selettore nativo macOS)
    - *Chiedi ogni volta* (`ask`, richiesto una sola volta prima di avviare la coda)
- **Gestione Collisioni Nomi Output**: Riconoscimento automatico e numerazione progressiva sincronizzata `(2)`, `(3)` per `.txt` e `.docx` in caso di file con lo stesso nome o file già esistenti.
- **Verifica Aggiornamenti GitHub Releases**: Worker asincrono non bloccante con rate-limit a 24 ore e voce nel menu `Aiuto` ➔ `Verifica Aggiornamenti...`.
- **Nuovo Algoritmo Denominazione Intelligente**: Salvaguardia assoluta dei titoli personalizzati (es. `EGI 12 novembre.m4a` ➔ `Trascrizione EGI 12 novembre.docx` e `EGI 20261012_1530.m4a` ➔ `Trascrizione EGI - 12-10-26 - 15.30.docx`).
- **Supporto Bilingue Completo**: Selettore istantaneo Italiano 🇮🇹 / English 🇬🇧 con bandiere native.
- **Pulsanti Tattili Liquid Glass**: Nuovi controlli con geometria super-squircle, riflessione del cursore e animazioni elastiche su curve di Bézier.
- **Indicatore Dinamico RAM di Sistema**: Visualizzatore grafico orizzontale in tempo reale della memoria unificata in uso.

### Migliorato
- **Persistenza Impostazioni Utente**: Memorizzazione in `QSettings` della modalità (automatica o manuale), del modello preferito (Large-v3 o Turbo), della lingua audio selezionata e dei formati di esportazione (`.txt` e `.docx`).
- **Supporto Ricorsivo Cartelle Drag & Drop**: Il trascinamento di cartelle nell'area di lavoro analizza ora ricorsivamente tutti i file multimediali supportati (incluso `.aiff`).
- **Calcolo Preciso dei Tempi e della Pausa**: Il timer di avanzamento e il calcolo della velocità escludono il tempo trascorso in pausa, prevenendo salti anomali nelle stime ETA.
- **Robustezza Notifiche macOS**: Sanitizzazione completa dei caratteri escape (`\"` e `\\`) nelle chiamate AppleScript e timeout di sicurezza a 5 secondi.
- **Protezione Concorrenza Stop Trascrizione**: Disconnessione atomica del segnale `coda_terminata` in fase di annullamento per evitare callback duplicate dell'interfaccia.
- **Finestra Aggiornamenti GitHub (`UpdateDialog`)**: Icona nativa dell'app nell'intestazione, gerarchia visiva dedicata (pulsante primario indaco, *Più tardi* neutro, *Ignora questa versione* discreto con bordo sottile), supporto link cliccabili e HTML-escaping nelle Release Notes, selezione precisa dell'asset `.dmg`/`.zip` macOS con fallback su `html_url`, gestione separata tra rinvio 24h (`snoozed_update_version`/`snoozed_update_until`) e versione ignorata (`skipped_update_version`), e deduplica nella stessa sessione.
- **Sottomenu Destinazione Trascrizioni**: Spostate le opzioni di salvataggio dentro il sottomenu dedicato `Impostazioni ➔ Salva trascrizioni in ▸` (`Save transcriptions to ▸` in EN) per massima chiarezza visiva.
- **Annullamento Reale durante Download Modello**: Se il modello non è ancora in cache locale all'avvio, viene mostrato un solo pulsante **Annulla download** (nascondendo *Pausa*) collegato a `tqdm` annullabile su `snapshot_download` e reset asincrono non bloccante della UI.
- **Raffinamento Trasparenza Privacy**: Aggiornata la dicitura da "100% Offline" a "Trascrizione 100% Locale" per rispecchiare fedelmente la presenza del controllo aggiornamenti su GitHub Releases.
- Migliorato il parsing degli errori di Hugging Face Hub con timeout resilienti (300s download, 60s etag).
- Rilascio completo della memoria Metal tramite `mx.clear_cache()` al termine di ciascuna operazione.

---

## [2.7.0] — Ottobre 2026
### Aggiunto
- Supporto hardware per la **Touch Bar dei MacBook Pro** tramite `libtouchbar.dylib`.
- Supporto all'esportazione simultanea in Microsoft Word (`.docx`) e testo semplice (`.txt`).
- Rilevamento automatico della configurazione hardware e selezione dinamica tra **Large-v3 Standard** e **Turbo**.

---

## [2.0.0] — Ottobre 2026
- Prima implementazione basata su framework nativo Apple MLX per chip Apple Silicon.
- Interfaccia grafica completa con coda Drag & Drop reattiva.
