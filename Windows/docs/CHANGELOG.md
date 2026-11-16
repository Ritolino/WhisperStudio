# Whisper Windows — Registro Modifiche & Changelog

## [3.0.5] — Novembre 2026
### Modificato
- **Allineamento UI al design macOS (Apple Squircle Concentrico)**: layout piatto senza card flottanti (sidebar 295px + divisore 1px; pannello destro con header coda / area contenuto / dock azioni separati da bordi 1px); titolo `Whisper Studio` con sottotitolo `Versione 3.0.5 • PyQt6` e badge hardware sotto; card RAM/VRAM con barra capsula 6px a tinta di pressione (indigo/ambra/rosso); `AnimatedSegmentedSwitch` squircle (raggio 10, cursore indigo pieno raggio 7, altezza 32); card modello automatico con icona + spunta; pulsanti-card modello manuale senza contenitore; formati export in card raggruppata con switch `AppleSwitchCheckBox` 36x20 (ordine .docx poi .txt); drop zone centrata max 460px con icona `waveform.badge.plus` vettoriale; barra progresso piatta 10px; icona app con maschera squircle di LM Studio.
- **Regola pulsanti dock**: a riposo e' visibile un solo pulsante (**Avvia Trascrizione** oppure **Scarica modello** se il modello non e' in cache); **Pausa** e **Annulla** compaiono solo durante download/trascrizione (ordine Pausa, Annulla come macOS).

### Aggiunto
- **Allineamento Versione a `3.0.5`**: Aggiornata la versione dell'applicazione (`APP_VERSION`, `AppUserModelID`, `STRINGS`, `HelpGuideDialog`, `README` e istruzioni) per allineare le release Windows e macOS.
- **Migrazione Build Standalone a Python 3.12 (64-bit) & CUDA 12 / cuDNN 9**: Ricompilato il bundle portatile (`WhisperStudio.exe` + `_internal/`) in ambiente isolato `Windows/.venv` su **Python 3.12.10 (64-bit)** con `PyQt6 6.12.1`, `faster-whisper 1.2.1`, `ctranslate2 4.9.0`, `nvidia-cublas-cu12`, `nvidia-cuda-nvrtc-cu12` e `nvidia-cudnn-cu12 9.28.1.4` (`PyInstaller 6.22.3`, `upx=False`).
- **Rinomina Eseguibile & Spec (`WhisperStudio.exe` / `WhisperStudio.spec`)**: Rinominati eseguibile standalone e file spec PyInstaller da `WhisperPortable` a `WhisperStudio` per coerenza con il nome del progetto su tutte le piattaforme.
- **Download Modello Dedicato ("Scarica modello", "Pausa download", "Annulla download")**:
  - Se il modello selezionato non è in cache locale (`is_model_cached`), il pulsante principale nel dock diventa **⬇️ SCARICA MODELLO** (attivo anche a coda vuota) tramite il nuovo worker dedicato `ModelDownloadWorker`.
  - Durante il download sono disponibili **⏸ PAUSA DOWNLOAD** (interrompe conservando i file `.part` per la ripresa HTTP `Range`) e **■ ANNULLA DOWNLOAD** (interrompe ed elimina i file `.part` e la cartella incompleta dalla cache).
  - Visualizzazione velocità decimale `MB/s` (`1_000_000`) e MB scaricati/totali.
- **Switch a Capsula a 2 Vie Animati (`AnimatedSegmentedSwitch`)**:
  - Sostituiti i pulsanti separati asimmetrici con switch animati a 2 vie sia per la modalità motore (**Automatica | Manuale**) sia per la lingua audio (**Italiano/English | Rileva Auto**) con supporto icone bandiera vettoriali.
- **Vincolo Mutuo sui Formati di Esportazione**:
  - Impedito lo spegnimento simultaneo di `.txt` e `.docx`: disattivando l'unico formato attivo, l'altro viene riattivato automaticamente.

### Migliorato
- **Filtri Anti-Ripetizione & Anti-Allucinazione (`Turbo` & `Large-v3`)**: Aggiunti a `transcribe_kwargs` i parametri `repetition_penalty=1.1`, `no_repeat_ngram_size=4` e `hallucination_silence_threshold=2.0`, più deduplica automatica dei segmenti brevi consecutivi identici (`<= 3` parole, es. ripetizioni di `"Grazie."` nel brusio finale).
- **Icone Compatte & Reset Coda**: Sostituiti i separatori testuali con icone compatte per durata/peso/tempi nelle card e nel riepilogo inferiore (`⏱`, `⏳`, `💾`); aggiunto reset automatico a `0%` della progress bar e stato *Pronto* allo svuotamento della coda o rimozione dell'ultimo file.
- **Drag Interno Puro Qt, Scroll Live & Hardening Anti-Falso Positivo AV (`BUG-03` / `DEC-015` / `R-WIN-03`)**:
  - Sostituito `QDrag.exec()` (loop modale OLE) per il riordino interno delle card `in_attesa` con trascinamento puro Qt (`QueueItemCard` + `QueueListWidget`: ghost `QLabel` trasparente agli eventi mouse, forwarding fluido della rotellina tramite `wheelEvent`/`handle_drag_wheel` e auto-scroll ai bordi con `QTimer`), rimuovendo qualsiasi hook Win32 (`SetWindowsHookExW`).
  - Inserito caching persistente dell'handle `nvml.dll` (`_NVML_LIB` / `_NVML_INITIALIZED`) per evitare caricamenti ripetuti ogni 2,5s e sospensione automatica del polling RAM/VRAM e dei check aggiornamenti GitHub mentre `ModelDownloadWorker` è attivo.
  - Aggiornato colore ambra `#f59e0b` per gli avvisi non ottimali sul modello Turbo/Large e testo semplificato *"Salvataggio automatico senza sovrascrivere i file esistenti."*.

## [2.7.5] — Novembre 2026
### Aggiunto
- **Menu Impostazioni & Sottomenu Destinazione (`Salva trascrizioni in`)**:
  - Nuovo menu nativo `Impostazioni` posizionato tra `Lingua` e `Aiuto`.
  - Toggle `Controlla automaticamente gli aggiornamenti` (`auto_check_updates`).
  - Toggle `Ricorda l'ultima modalità del motore` (`remember_engine_mode`, predefinito attivo). Se disattivato, all'avvio la modalità iniziale è sempre Automatica.
  - Sottomenu dedicato `Salva trascrizioni in` (`Save transcriptions to` in EN) con 3 opzioni radio esclusive (`dest_mode`):
    - `Accanto al file originale` (predefinito)
    - `Cartella personalizzata…` (con selezione via `QFileDialog`, validazione cartella e visualizzazione abbreviata nel menu)
    - `Chiedi ogni volta` (richiesto una sola volta per l'intera coda all'avvio).
- **UI & Annullamento Reale durante il Download del Modello**:
  - Se il modello selezionato non è ancora presente in cache locale all'avvio della trascrizione, viene mostrato un solo pulsante **Annulla download** (`Cancel download` in EN) al posto di *Pausa* e *Annulla*, interrompendo il download in sicurezza senza bloccare l'interfaccia.
- **Raffinamento Finestra Aggiornamenti (`UpdateDialog` & `UpdateCheckWorker`)**:
  - Icona app ad alta risoluzione al posto dell'emoji, gerarchia pulsanti migliorata (`#6366f1` per *Scarica Aggiornamento*, neutro per *Più tardi*, bordo sottile per *Ignora questa versione*).
  - Supporto completo Markdown con `html.escape`, link `[testo](url)` e URL nudi cliccabili in `QTextBrowser`.
  - Selezione precisa dell'asset Windows (`.zip`/`.exe`/`.msi` con token `windows`/`win`, escludendo pacchetti macOS/Linux) tramite `select_platform_asset_url`.
  - Rinvio a 24 ore (`snoozed_update_version` / `snoozed_update_until`) distinto da *Ignora*, deduplica notifiche in sessione (`_session_notified_versions`, `_update_dialog_open`) e bypass di entrambi nella verifica manuale.
- **Accorciamento Footer UI**: Stringa `footer` compattata a `"🔒 Trascrizione 100% Locale"` / `"🔒 100% Local Transcription"` per evitare troncamenti sul bordo della finestra.
- **Risoluzione Univoca Nomi & Suffissi Progressivi (`resolve_unique_output_paths`)**:
  - Eliminata qualsiasi sovrascrittura accidentale: se il file esiste già o collisioni avvengono in coda, assegna suffissi progressivi identici `(2)`, `(3)` sia al file `.txt` che al file `.docx`.
- **Verifica Aggiornamenti GitHub Releases**: Aggiunto worker in background e voce nel menu `Aiuto` ➔ `Verifica Aggiornamenti...` (`Check for Updates...`).
- **Denominazione Intelligente dei File**: Salvaguardia dei titoli personalizzati come `EGI 12 novembre.m4a` e formattazione automatica dei file con data/ora generica.
- **Supporto Bilingue Fluido**: Lingua commutabile a caldo da menu con bandiere vettoriali nitide.
- **Rilascio Completo della Memoria**: Deallocazione totale del modello e invocazione del garbage collector alla fine del batch.

### Migliorato
- **Persistenza Impostazioni Utente**: Memorizzazione in `QSettings` dello stato dei toggle di esportazione (`export_txt` e `export_docx`) e della lingua audio selezionata (Italiano/Inglese primario vs Rilevamento automatico), ripristinandoli all'avvio dell'applicazione.
- **Supporto Drag & Drop Ricorsivo per Cartelle**: Il trascinamento di cartelle nell'area di lavoro analizza ed estrae ricorsivamente tutti i file multimediali supportati presenti nelle sottocartelle.
- **Calcolo Preciso dei Tempi e della Pausa**: Tracciamento accurato della durata trascorsa in pausa (`dt_pause`) sottratta da `t_trascorso_file` e dal calcolo globale, eliminando falsi picchi di velocità o derive anomale nella stima del tempo residuo (ETA).
- **Estensione File Aggiuntiva**: Aggiunto il supporto completo ai file `.aiff` sia nel set `VALID_EXTENSIONS` che nei filtri di selezione delle finestre di dialogo file.
- **Raffinamento Trasparenza Privacy**: Aggiornata la dicitura da "100% Offline" a "Trascrizione 100% Locale" per riflettere con accuratezza la presenza del controllo asincrono degli aggiornamenti via GitHub Releases.
- Migliorata la stima del tempo residuo globale (ETA) calcolato sull'intera coda di file.
- Logging centralizzato in `%LOCALAPPDATA%\WhisperStudio\logs` per mantenere pulita la cartella portatile.

---

## [2.7.0] — Ottobre 2026
- Precaricamento dinamico cuBLAS 12 per supporto immediato alle GPU NVIDIA RTX 40 / 30 / 20 serie.
- Fallback trasparente su CPU Intel/AMD con quantizzazione INT8.
- Esportazione simultanea `.txt` e `.docx` con protezione contro il blocco file di Microsoft Word.
