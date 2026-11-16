# Whisper MacOS — Registro Rischi, Bug Noti & Soluzioni

## 1. Rischi Noti & Mitigazioni

### R-MAC-01: Blocco Gatekeeper al Primo Avvio
- **Descrizione:** Essendo un'applicazione distribuita al di fuori del Mac App Store senza certificato Apple Developer a pagamento, macOS Gatekeeper blocca il lancio con avviso "Sviluppatore non verificato".
- **Mitigazione:**
  - Spostare `Whisper Studio.app` in **`/Applications`**, provare ad aprirla una volta e confermare in **Impostazioni di Sistema ➔ Privacy e Sicurezza ➔ Apri comunque** (oppure clic destro ➔ *Apri*).
  - In alternativa da Terminale: `xattr -dr com.apple.quarantine "/Applications/Whisper Studio.app" && open "/Applications/Whisper Studio.app"`.

### R-MAC-02: Saturazione Memoria su Mac sotto i 24 GB (8/16 GB)
- **Descrizione:** L'uso del modello `Large-v3 Standard` su Mac con 8 GB o 16 GB di memoria unificata condivisa con macOS/GPU/app lascia poco margine e può causare swap su disco SSD o rallentamenti.
- **Mitigazione:**
  - L'applicazione rileva la RAM fisica all'avvio: se è inferiore a 24 GB (es. 8 GB e 16 GB), seleziona in automatico il modello **Large-v3 Turbo** (ottimizzato e a basso consumo di memoria).
  - Mostra un avviso informativo qualora l'utente cerchi di forzare `Large-v3 Standard` in modalità manuale.

### R-MAC-03: Dipendenza dal Binario FFmpeg
- **Descrizione:** Senza un binario FFmpeg compatibile, la decodifica audio fallisce.
- **Mitigazione:**
  - Un binario FFmpeg arm64 autonomo è incluso direttamente dentro il bundle applicativo e referenziato tramite `find_ffmpeg()` con fallback su `/opt/homebrew/bin/ffmpeg` o `/usr/local/bin/ffmpeg`.

---

## 2. Bug Risolti

- **BUG-01 (Loop di Allucinazione su Silenzi Lunghi):** Risolto impostando `condition_on_previous_text=False` in `mlx_whisper.transcribe`.
- **BUG-02 (Cancellazione Titolo Personalizzato Utente):** Risolto nel modulo `generate_output_path`: i titoli personalizzati come `EGI` vengono ora preservati anche se il file contiene un timestamp numerico.
- **BUG-03 (Calcolo Distorto ETA dopo la Pausa):** Risolto in `ThreadStdoutInterceptor` e `TrascrizioneWorkerThread`: il tempo trascorso durante la pausa viene accumulato e sottratto dal calcolo del tempo trascorso effettivo, garantendo una stima ETA sempre accurata.
- **BUG-04 (Doppio Callback su Stop Trascrizione):** Risolto disconnettendo atomica il segnale `coda_terminata` prima del `wait()` del thread durante l'annullamento.
- **BUG-05 (Notifiche AppleScript con Virgolette nei Titoli):** Risolto con l'escape completo dei caratteri speciali prima dell'esecuzione del comando `osascript`.

---

## 3. Registro Cronologico Bug Report & Bug Fix (v3.0.5)

### 2026-11-14 18:18 — Bug grafico e indicatore di inserimento nel riordino coda
- **Scoperto:** `2026-11-14 18:18`
- **Risolto:** `2026-11-14 19:00`
- **Sintomo:** Lampeggio visivo durante il trascinamento nella coda; la linea viola di destinazione non si posizionava intuitivamente tra le card (specialmente sotto l'ultima riga).
- **Causa:** Target di drop sull'intera card con `LazyVStack(spacing: 8)` che creava zone morte/sfasate durante il drag.
- **Soluzione:** Sostituito con doppia drop-zone superiore/inferiore per ogni riga + zona dedicata in fondo in [`MainWindowView.swift`](../App/Sources/Views/MainWindowView.swift), eliminazione del flicker e linea viola tra le card con pallino guida.

### 2026-11-14 19:30 — Progresso download modello assente e barra parziale allo 0%
- **Scoperto:** `2026-11-14 19:30`
- **Risolto:** `2026-11-14 20:15`
- **Sintomo:** Nessuna velocità/avanzamento mostrato durante il download del modello; barra di avanzamento visivamente leggermente piena allo 0%; errore `Unknown argument(s): {'name': 'huggingface_hub.snapshot_download'}` e conteggio MB/s non allineato a macOS.
- **Causa:** `tqdm` disabilitato su pipe non-TTY, argomento `name` non supportato nella sottoclasse `_AbortableTqdm` passata a `snapshot_download`, symlink blob nella cache Hugging Face non risolti con `.resolvingSymlinksInPath()`, e larghezza minima del `Capsule` allo 0%.
- **Soluzione:** Implementato `_AbortableTqdm` compatibile con `tqdm_class` su finestra mobile 1s con base decimale (`1_000_000` MB/s), risolti i symlink cache, aggiunti pulsanti **Scarica modello** / **Pausa download** / **Annulla download**, e sostituita la progress bar con `FlatProgressBar` vuota allo 0%.

### 2026-11-14 22:13 — Errore `"Empty stdin command"` premendo Annulla
- **Scoperto:** `2026-11-14 22:13`
- **Risolto:** `2026-11-14 23:16`
- **Sintomo:** Premendo *Annulla* subito dopo l'avvio appariva un alert `"Empty stdin command"`.
- **Causa:** `cancelWithTimeout` chiudeva `stdin` immediatamente dopo `cancel`; se `WhisperEngine` leggeva `stdin` già chiuso all'avvio emetteva `fatal_error("Empty stdin command")`.
- **Soluzione:** In [`whisper_engine.py`](../Engine/whisper_engine.py), `stdin` vuoto o `cancel` iniziale emettono `batch_cancelled`; in [`AppState.swift`](../App/Sources/AppState.swift), `fatal_error` durante `runState == .stopping` chiude in modo pulito senza alert.

### 2026-11-14 23:19 — Comandi `remove_file` / `append_files` ignorati da Swift `Codable`
- **Scoperto:** `2026-11-14 23:19`
- **Risolto:** `2026-11-14 23:22`
- **Sintomo:** Rimozione o aggiunta file in coda durante la trascrizione non sincronizzata con il backend Python.
- **Causa:** `RemoveFileCommand` e `AppendFilesCommand` in [`EngineProtocol.swift`](../App/Sources/Models/EngineProtocol.swift) usavano `let cmd = "..."`: Swift `Codable` esclude le proprietà `let` con valore iniziale dalla codifica JSON.
- **Soluzione:** Convertiti entrambi in `var cmd: String = "..."` e aggiunto `ReorderFilesCommand` per il riordino in tempo reale dei file `.waiting`.

### 2026-11-14 23:25 — Errore `"First command must be start_batch or download_model"` e processo zombie in background
- **Scoperto:** `2026-11-14 23:25` (rilevato da `~/Library/Logs/WhisperStudio/engine.log` alle `22:25:33Z`)
- **Risolto:** `2026-11-14 23:31`
- **Sintomo:** Rimuovendo un file durante la trascrizione appariva l'alert `First command must be start_batch or download_model`, i pulsanti Pausa/Annulla sparivano tornando su *Avvia Trascrizione*, ma il motore continuava a trascrivere i file originali in background aggiornando `2/6` e `7%` anche a coda svuotata.
- **Causa:**
  1. `whisper_engine.py` non chiamava `multiprocessing.freeze_support()`: un sottoprocesso `multiprocessing` avviato internamente in PyInstaller entrava in `main()` e si bloccava su `sys.stdin.readline()`, intercettando ("rubando") il comando `remove_file` destinato al padre ed emettendo `fatal_error` sullo `stdout` condiviso.
  2. In `AppState.swift`, `fatal_error` riportava `runState = .idle` senza terminare `processManager` né filtrare eventi tardivi.
- **Soluzione:** Aggiunto `multiprocessing.freeze_support()` + guardia CLI in [`whisper_engine.py`](../Engine/whisper_engine.py); in [`AppState.swift`](../App/Sources/AppState.swift), `fatal_error` termina ora `processManager` (`cancelWithTimeout`) e `handleEngineEvent` ignora eventi quando `runState == .idle`. Aggiunto inoltre salvataggio persistente dei log su `~/Library/Logs/WhisperStudio/engine.log`.

### 2026-11-14 23:35 — Contatore RAM incoerente con Pico / Monitoraggio Attività & Barra non azzerata a coda svuotata
- **Scoperto:** `2026-11-14 23:35`
- **Risolto:** `2026-11-14 23:36`
- **Sintomo:** Il valore di RAM usata mostrato nella sidebar differiva da quello mostrato da Pico / Monitoraggio Attività; inoltre svuotando la coda riga per riga dopo una trascrizione, la barra di avanzamento restava bloccata al 100%.
- **Causa:**
  1. [`SystemMemoryService.swift`](../App/Sources/Services/SystemMemoryService.swift) sommava `active_count + wire_count + compressor_page_count` con `getpagesize()` invece della Formula A ufficiale XNU/Activity Monitor usata da Pico (`(internal_page_count - purgeable_count) + wire_count + compressor_page_count` con `vm_kernel_page_size`).
  2. `removeItem(_:)` in [`AppState.swift`](../App/Sources/AppState.swift) non azzerava `totalProgressPercent`, i timer e `statusMessage` quando la coda diventava vuota fuori esecuzione.
- **Soluzione:** Allineato `SystemMemoryService.currentSnapshot()` alla Formula A di Pico / Activity Monitor e aggiunto il reset completo di barra e contatori quando `queue.isEmpty` in `removeItem(_:)` e `clearQueue()`.
