# Whisper Windows — Registro Rischi, Bug Noti & Soluzioni

## 1. Rischi Noti & Mitigazioni

### R-WIN-01: Driver NVIDIA Non Aggiornati
- **Descrizione:** Se i driver della scheda video NVIDIA sono troppo vecchi, le DLL CUDA 12 non possono dialogare con il driver kernel.
- **Mitigazione:** Il codice gestisce l'eccezione all'inizializzazione del modello ed esegue un fallback pulito su CPU in modalità multithreading `int8`, notificando l'utente nei log senza bloccare l'app.

### R-WIN-02: Blocco File su Documenti Word Aperti
- **Descrizione:** In ambiente Windows, aprire un `.docx` in Microsoft Word impedisce la scrittura o sovrascrittura da parte di altri processi.
- **Mitigazione:** Il modulo `safe_save_transcription` tenta il salvataggio: in caso di blocco, genera automaticamente un file incrementale `(1)`, `(2)`, ecc.

### R-WIN-03: Falsi Positivi Antivirus (`PDM:Exploit.Win32.Generic.nblk`)
- **Descrizione:** Gli eseguibili generati con PyInstaller (`--onedir` o `--onefile`) non firmati digitalmente possono innescare falsi allarmi comportamentali (es. Kaspersky `PDM:Exploit.Win32.Generic.nblk`) durante il download dei modelli da Hugging Face, quando coesistono connessioni HTTPS concorrenti, scrittura di grossi file binari nella cartella applicativa e chiamate cicliche `ctypes` (`nvml.dll` / `kernel32`) o hook Win32.
- **Mitigazione:** Distribuzione `--onedir` (`WhisperStudio.exe` + `_internal`), caching dell'handle `nvml.dll` (caricamento singolo invece che ogni 2,5s), sospensione del polling memoria e del check aggiornamenti GitHub durante il download dei modelli, ed eliminazione di `SetWindowsHookExW` sostituendo `QDrag` interno con un trascinamento puro Qt. Resta consigliata l'esclusione della cartella applicativa nell'antivirus in caso di eseguibile non firmato.

---

## 2. Bug Risolti
- **BUG-01 (Flag Emoji Disegnate come Lettere):** Risolto implementando `create_flag_icon` con disegno vettoriale in `QPainter`.
- **BUG-02 (Cancellazione Titolo Personalizzato Utente):** Risolto integrando il parser semantico che mantiene il nome utente e pulisce solo i registratori generici.
- **BUG-03 (Scroll con Rotellina Bloccato Durante Drag & Drop nella Coda — 2026-11-16 00:45):**
  - **Sintomo:** Trascinando una card (`QueueItemCard`) nella coda (`QueueListWidget`) per riordinarla, la rotellina del mouse non scorreva la lista, rendendo impossibile raggiungere gli elementi fuori dallo schermo in liste lunghe.
  - **Causa Radice:** Su Windows, `QDrag.exec()` avvia il loop modale OLE `DoDragDrop()` che cattura l'input del mouse e non inoltra `WM_MOUSEWHEEL` a `QListWidget.wheelEvent()`; inoltre l'uso iniziale di `SetWindowsHookExW` poteva risultare sospetto ai moduli comportamentali antivirus. (`DEC-015`).
  - **Soluzione:** Sostituito `QDrag.exec()` per il riordino interno con un drag-and-drop puro Qt (`QueueItemCard` + `QueueListWidget`: overlay ghost `QLabel` trasparente agli eventi mouse, forwarding diretto di `wheelEvent` tramite `handle_drag_wheel` / `scroll_during_drag` e auto-scroll fluido ai bordi superiore/inferiore tramite `QTimer`), senza alcun hook Win32 (`SetWindowsHookExW`). Il drop di file esterni da Esplora Risorse resta gestito da `setAcceptDrops(True)`.
