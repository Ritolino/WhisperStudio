# Whisper Windows — Registro Decisioni Architetturali (DEC)

### DEC-001: Adozione di Faster-Whisper (CTranslate2) al posto di OpenAI Whisper Vanilla
- **Data:** Ottobre 2026
- **Contesto:** Il pacchetto vanilla di OpenAI Whisper basato su PyTorch pesa oltre 3 GB di sole librerie Python e ha tempi di avvio lenti.
- **Decisione:** Utilizzare `faster-whisper` (motore CTranslate2).
- **Conseguenze:** Velocità 4x superiore, minor consumo di memoria VRAM (inferenza nativa in `float16`) e supporto CPU altamente ottimizzato in `int8`.

### DEC-002: Precaricamento Esplicito delle Librerie CUDA 12 (`_preload_cuda_libraries`)
- **Data:** Ottobre 2026
- **Contesto:** Windows spesso non trovava `cublasLt64_12.dll` se l'utente non aveva installato il CUDA Toolkit di sistema, provocando crash o fallback involontario su CPU.
- **Decisione:** Integrare le DLL direttamente dentro `_internal` e richiamare `os.add_dll_directory` e `ctypes.CDLL` all'avvio.
- **Conseguenze:** Accelerazione GPU funzionante "out of the box" su qualsiasi PC Windows con driver NVIDIA aggiornati.

### DEC-003: Disegno Personalizzato delle Bandiere Vettoriali (`create_flag_icon`)
- **Data:** Ottobre 2026
- **Contesto:** Il font Segoe UI Emoji di Windows non implementa i caratteri delle bandiere regionali (mostrando es. lettere separate "IT" e "GB").
- **Decisione:** Implementare un painter vettoriale QPainter che disegna le bandiere ad alta risoluzione (16x12 fino a 64x45 px) con antialiasing e angoli arrotondati.
- **Conseguenze:** Visualizzazione pixel-perfect delle bandiere sia nei pulsanti che nei sottomenu.

### DEC-004: Protezione contro il File Locking di Windows
- **Data:** Ottobre 2026
- **Contesto:** Su Windows, se un documento Word `.docx` precedentemente trascritto è ancora aperto in Microsoft Word, la sovrascrittura fallisce con errore `PermissionError: [Errno 13] Permission denied`.
- **Decisione:** Implementare un ciclo di auto-incremento `(1)`, `(2)`, ecc., garantendo che la trascrizione venga sempre salvata senza crashare l'applicazione.

### DEC-005: Preservazione dei Titoli Personalizzati (`EGI`)
- **Data:** Novembre 2026
- **Contesto:** Uniformato alla versione macOS: preserva i titoli custom utente come `EGI 12 novembre` o `EGI 20261012_1530` senza sostituire l'intero nome con il solo timestamp.

### DEC-006: Persistenza Formati e Lingua Audio in QSettings
- **Data:** Novembre 2026
- **Contesto:** Ad ogni riavvio dell'applicazione i toggle di esportazione `.docx` e `.txt` e la selezione lingua audio tornavano ai valori di default, costringendo l'utente a riconfigurarli.
- **Decisione:** Salvare lo stato di `export_txt`, `export_docx` e `audio_lang_idx` in `QSettings("WhisperStudio", "WhisperStudioWindows")` e ripristinarli all'avvio.
- **Conseguenze:** Esperienza utente fluida e coerente con la versione macOS.

### DEC-007: Trasparenza Privacy e Trascrizione 100% Locale
- **Data:** Novembre 2026
- **Contesto:** L'applicazione include un worker per il controllo non bloccante degli aggiornamenti via API pubbliche di GitHub. Dichiarare "100% Offline / Zero connessioni" risultava impreciso.
- **Decisione:** Riformulare la comunicazione in "Trascrizione 100% Locale / I tuoi file restano sul PC", evidenziando che l'audio e i testi non lasciano mai la macchina ospite mentre l'unica connessione opzionale riguarda il version check.
- **Conseguenze:** Massima chiarezza e trasparenza verso l'utente finale.

### DEC-008: Menu Impostazioni Integrato e Risoluzione Destinazione
- **Data:** Novembre 2026
- **Contesto:** Necessità di consentire la configurazione della cartella di destinazione (originale, custom o chiedi ogni volta), del controllo aggiornamenti e della memoria modalità motore senza appesantire la finestra principale con modali o wizard.
- **Decisione:** Integrare tutte le preferenze nel menu principale `Impostazioni` con sottomenu dedicato `Salva trascrizioni in` (`QActionGroup` radio), persistenza atomica su `QSettings("WhisperStudio", "WhisperStudioWindows")` e risoluzione preliminare univoca della cartella di destinazione per tutta la coda tramite `resolve_unique_output_paths`.
- **Conseguenze:** Flusso d'uso immediato, nessun pop-up fastidioso per file singolo e allineamento perfetto con macOS.

### DEC-009: UI Dedicata e Annullamento Reale del Download Modello
- **Data:** Novembre 2026
- **Contesto:** Il download HTTP streaming da Hugging Face non supporta la pausa a metà trasferimento; mostrare il pulsante *Pausa* durante lo scaricamento risultava fuorviante.
- **Decisione:** Rilevare la presenza in cache locale prima di avviare il worker (`find_local_model_path` + `is_model_dir_complete`); se il modello manca, nascondere `btn_pausa` e trasformare `btn_ferma` in un unico pulsante **Annulla download**, mantenendo reattivo il loop di attesa e ripristinando i controlli standard a download ultimato.
- **Conseguenze:** Interfaccia coerente con lo stato reale delle operazioni e arresto pulito senza blocchi UI.

### DEC-010: Hardening Markdown, Asset Piattaforma e Snooze 24h in UpdateDialog
- **Data:** Novembre 2026
- **Contesto:** L'updater doveva evitare falsi download di pacchetti macOS su Windows, prevenire HTML injection nelle note di rilascio e distinguere il rinvio temporaneo (*Più tardi*) dal rifiuto permanente (*Ignora questa versione*).
- **Decisione:** Introdurre `select_platform_asset_url` (whitelist token Windows / blacklist macOS e Linux), `_render_inline_markdown` basato su `html.escape`, salvataggio separato di `snoozed_update_version`/`snoozed_update_until` e deduplica di sessione (`_session_notified_versions`).
- **Conseguenze:** Auto-updater sicuro, preciso nella scelta dell'installer e rispettoso delle scelte utente.

### DEC-011: Download Modello Standalone con Pausa/Annulla Reali e Switch a 2 Vie (`AnimatedSegmentedSwitch`)
- **Data:** Novembre 2026
- **Contesto:** Allineamento UX con la versione macOS v3.0.0 per consentire il pre-download del modello anche a coda vuota, distinguere chiaramente *Pausa download* (conserva `.part` per ripresa `Range`) da *Annulla download* (pulisce la cache parziale), uniformare la geometria degli switch a 2 vie e garantire almeno un formato di output attivo.
- **Decisione:** Introdurre `ModelDownloadWorker`, `is_model_cached`, `cleanup_partial_model_download`, il widget animato `AnimatedSegmentedSwitch` per modalità motore e lingua audio, e il vincolo mutuo tra `chk_txt` e `chk_docx`.
- **Conseguenze:** Esperienza coerente su entrambe le piattaforme desktop senza cambiare lo stack PyQt6 / Faster-Whisper su Windows.

### DEC-012: Migrazione Build Standalone a Python 3.12 (64-bit) con `.venv` Isolato e CUDA 12 / cuDNN 9
- **Data:** Novembre 2026
- **Contesto:** Allineamento del runtime Python di build tra macOS (`3.12.16`) e Windows (`3.12.10`) per garantire massima compatibilità delle wheel binarie (`ctranslate2`, `onnxruntime`, `PyQt6`, `av`) ed evitare dipendenze sporche dall'ambiente globale di sistema.
- **Decisione:** Creare un ambiente virtuale isolato `Windows/.venv` basato su **Python 3.12.10 (64-bit)** con `requirements.txt` aggiornato (`nvidia-cublas-cu12`, `nvidia-cuda-nvrtc-cu12`, `nvidia-cudnn-cu12`) e compilare `WhisperStudio.exe` + `_internal/` tramite `WhisperStudio.spec` con deduplicazione delle DLL CUDA.
- **Conseguenze:** Bundle standalone `v3.0.5` riproducibile, isolato, compatibile out-of-the-box con GPU NVIDIA CUDA 12 e fallback CPU `int8`.

### DEC-013: Filtri Anti-Ripetizione e Deduplica Segmenti Brevi (`Turbo` & `Large-v3`)
- **Data:** Novembre 2026
- **Contesto:** Nei test su registrazioni d'aula con brusio di fondo, il modello `Turbo` (con decoder più leggero rispetto a `Large-v3`) poteva generare ripetizioni consecutive di segmenti brevi (es. `"Grazie."` ripetuto 5 volte nel brusio finale) pur avendo `condition_on_previous_text=False` e `vad_filter=True`.
- **Decisione:** Aggiungere `repetition_penalty=1.1`, `no_repeat_ngram_size=4` e `hallucination_silence_threshold=2.0` in `transcribe_kwargs`, abbinati a una deduplica di post-processing che comprime i segmenti brevi consecutivi identici (`<= 3` parole normalizzate).
- **Conseguenze:** Riduzione drastica dei loop su `Turbo` e `Large-v3` senza alterare il parlato normale né introdurre latenza aggiuntiva.

### DEC-014: Allineamento Grafico Windows al Design System macOS
- **Data:** 2026-11-16
- **Contesto:** La UI Windows usava pannelli flottanti arrotondati, switch con checkbox e pulsanti sempre visibili; macOS e' il riferimento di design.
- **Decisione:** Replicare in PyQt6 la grammatica macOS (raggi 12/10/7, layout piatto a barre, switch squircle, card RAM, drop zone centrata, dock con pulsante unico a riposo). Pausa/Annulla visibili solo durante un'operazione; senza modello in cache l'unico pulsante e' Scarica modello.
- **Conseguenze:** Aspetto coerente tra piattaforme; nessun cambio di logica (stessi attributi widget: `btn_avvia`, `chk_txt`, `seg_mode`, ecc.).


### DEC-015: Drag Interno Puro Qt & Hardening Comportamentale Anti-Falso Positivo AV
- **Data:** 2026-11-16
- **Contesto:** Il loop modale OLE di `QDrag.exec()` bloccava `WM_MOUSEWHEEL` durante il riordino della coda e l'uso di `SetWindowsHookExW` / chiamate `ctypes.CDLL("nvml.dll")` ogni 2,5s / connessioni HTTPS concorrenti durante il download modelli poteva innescare il modulo euristico di Kaspersky (`PDM:Exploit.Win32.Generic.nblk`).
- **Decisione:** Sostituire `QDrag.exec()` per il riordino interno delle card con un drag-and-drop puro Qt (`QueueItemCard` + `QueueListWidget` con ghost `QLabel` trasparente agli eventi mouse, forwarding `wheelEvent` e auto-scroll ai bordi); cachare l'handle `nvml.dll`; sospendere polling VRAM/RAM e check aggiornamenti GitHub mentre `ModelDownloadWorker` è attivo.
- **Conseguenze:** Scroll con rotellina fluido durante il trascinamento senza alcun hook Win32 né `QDrag` OLE interno, e profilo comportamentale molto più pulito verso gli antivirus.
