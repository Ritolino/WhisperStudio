# Whisper MacOS — Registro Decisioni Architetturali (DEC)

### DEC-001: Scelta di Apple MLX rispetto a PyTorch / CTranslate2
- **Data:** Ottobre 2026
- **Contesto:** Su macOS con chip Apple Silicon (M1-M5), PyTorch e CTranslate2 non sfruttavano appieno la memoria unificata e Metal.
- **Decisione:** Adottare `mlx-whisper` (`Apple MLX`).
- **Conseguenze:** Throughput di trascrizione raddoppiato, minor consumo energetico, footprint di memoria compresso e zero riscaldamento anomalo.

### DEC-002: Disabilitazione Condizionamento su Testo Precedente (`condition_on_previous_text=False`)
- **Data:** Ottobre 2026
- **Contesto:** Whisper talvolta entrava in loop di allucinazioni ripetendo all'infinito frasi o parole durante silenzi prolungati nell'audio.
- **Decisione:** Impostare rigorosamente `condition_on_previous_text=False`.
- **Conseguenze:** Eliminazione totale dei loop allucinatori e riduzione del 50% dei tempi morti di fallback.

### DEC-003: Intercettore Stdout per Avanzamento Percentuale Senza Sottoprocessi
- **Data:** Ottobre 2026
- **Contesto:** L'esecuzione in-process non deve lanciare sottoprocessi per monitorare lo stato di `mlx_whisper`.
- **Decisione:** Implementare `ThreadStdoutInterceptor` che cattura i timestamp emessi da Whisper su stdout e calcola l'avanzamento esatto in base alla durata complessiva dell'audio.
- **Conseguenze:** Nessun secondo processo o icona duplicata nel Dock di macOS, architettura 100% in-process.

### DEC-004: Touch Bar Nativa tramite Libreria Dinamica C/Objective-C
- **Data:** Ottobre 2026
- **Contesto:** I MacBook Pro con Touch Bar necessitavano di controlli hardware rapidi per avvio, pausa e stop.
- **Decisione:** Scrivere `touchbar.m`, compilarlo in `libtouchbar.dylib` ed esporlo all'app PyQt6 tramite `ctypes`.
- **Conseguenze:** Controlli fluidi con pulsanti Liquid Glass visibili direttamente sulla barra hardware.

### DEC-005: Denominazione Intelligente dei File e Salvaguardia dei Titoli
- **Data:** Novembre 2026
- **Contesto:** File con nomi composti (es. `EGI 12 novembre.m4a` o `EGI 20261012_1530.m4a`) vedevano il nome "EGI" sovrascritto da un timestamp generico.
- **Decisione:** Separare i timestamp numerici dai titoli utente tramite regex semantiche. Preservare sempre il nome utente e pulire unicamente i nomi puramente generici (es. `20261012_1530_audio.mp3` ➔ `Trascrizione 12-10-26 - 15.30.docx`).

### DEC-006: Auto-Updater Asincrono da GitHub Releases (Stile Pico)
- **Data:** Novembre 2026
- **Contesto:** Necessità di avvisare gli utenti sulle nuove release stabili senza compromettere la privacy offline.
- **Decisione:** Controllo ritardato a 10s all'avvio con rate-limit a 24h e supporto a opt-out. Parsing SemVer e finestra `UpdateDialog` con note di rilascio.

### DEC-007: Persistenza di Stato Completa delle Preferenze Utente
- **Data:** Novembre 2026
- **Contesto:** Al riavvio dell'applicazione l'utente perdeva la configurazione selezionata (modalità manuale/automatica, modello preferito, lingua audio e formati di esportazione).
- **Decisione:** Integrare `QSettings` sia per le modalità di trascrizione che per i toggle dei formati e della lingua, ripristinandoli all'avvio con sanitizzazione dei dati.

### DEC-008: Menu Impostazioni Nativo su macOS MenuBar & Risoluzione Destinazione
- **Data:** Novembre 2026
- **Contesto:** Necessità di configurare aggiornamenti, persistenza del motore e destinazione di salvataggio (accanto all'originale, cartella personalizzata, chiedi ogni volta) senza introdurre finestre dedicate o anticipare SwiftUI/AppKit.
- **Decisione:** Aggiungere il menu `Impostazioni` su `QMenuBar` nativo (`File | Lingua | Impostazioni | Aiuto`), con azioni radio esclusive `QActionGroup`, riga secondaria non selezionabile per il path custom e risoluzione univoca dei nomi anti-collisione con suffisso progressivo sincronizzato tra `.txt` e `.docx`.

### DEC-009: Gestione Separata di Rinvio 24h ("Più tardi") e Versione Ignorata nell'Updater GitHub
- **Data:** Novembre 2026
- **Contesto:** Il semplice rate-limit di rete a 24h (`last_update_check_ts`) non distingueva tra un controllo periodico e il rinvio esplicito di una release da parte dell'utente, rischiando inoltre di nascondere una release ancora più recente o di non rispettare il rinvio rispetto a `skipped_update_version`.
- **Decisione:** Separare le chiavi `QSettings` in `skipped_update_version` (ignora permanente per quella versione nei controlli automatici), `snoozed_update_version` + `snoozed_update_until` (rinvio di 24h che non nasconde versioni successive con SemVer superiore) e mantenere la verifica manuale sempre libera di riproporre qualsiasi release disponibile. La selezione degli asset verifica i token di piattaforma ed estensioni valide (`.dmg`/`.zip` su macOS) con fallback su `html_url`.

### DEC-010: Pulsante Unico "Annulla download" e Interruzione Reale di `snapshot_download`
- **Data:** Novembre 2026
- **Contesto:** Durante il primo scaricamento di un modello Hugging Face (`snapshot_download`), `huggingface_hub` non supporta la pausa HTTP a metà trasferimento, rendendo il tasto *Pausa* inefficace e bloccando `wait()` sull'annullamento.
- **Decisione:** Se `is_model_locally_cached()` è falso all'avvio, nascondere `btn_pausa` e trasformare `btn_ferma` in **"Annulla download"**, ripristinando i due tasti solo all'emissione di `download_terminato`. Iniettare una sottoclasse `tqdm` abortabile in `snapshot_download` e usare `wait(400)` con gestione `_dangling_workers` in `ferma_trascrizione()` per riportare subito l'interfaccia allo stato pronto senza freeze.

### DEC-011: Migrazione a UI Nativa SwiftUI/AppKit (macOS 26+) con Helper Isolato `WhisperEngine` JSONL
- **Data:** Novembre 2026
- **Contesto:** L'applicazione PyQt6 macOS soffriva di un bundle pesante (~800 MB per runtime Qt), dipendenza da `touchbar.m`/`libtouchbar.dylib` e limiti nella resa nativa macOS Tahoe. Al contrario, `mlx-whisper`, `huggingface_hub` e `python-docx` non hanno ancora un equivalente Swift puro altrettanto maturo e preciso.
- **Decisione:** Separare nettamente l'UI dal motore neurale con la v3.0.5:
  1. **UI Nativa in Swift 6 (`SwiftUI` + `AppKit`)** per macOS 26.0+ Apple Silicon (`arm64`), con `UserDefaults`, `URLSession` updater, `NSOpenPanel`, `NSWorkspace`, `UNUserNotificationCenter` e `NSTouchBar` integrati nativamente.
  2. **Helper Headless `WhisperEngine`** (`whisper_engine.py` compilato via PyInstaller `--onedir` senza PyQt/Tk) collocato in `Contents/Resources/WhisperEngine/` per garantire firma `codesign` inside-out valida nonostante eventuali directory `.dist-info` in `_internal/`.
  3. **Protocollo IPC JSON Lines (`stdin`/`stdout`)**: l'helper scrive gli eventi esclusivamente su `sys.__stdout__` mentre i log librerie sono dirottati su `sys.stderr`; la pausa usa `SIGSTOP`/`SIGCONT` sull'albero di processo dell'helper e la cancellazione interrompe `_AbortableTqdm` o termina pulitamente il processo senza bloccare la GUI.
- **Conseguenze:** Eliminazione totale di Qt/PyQt6 da macOS, esperienza e latenza UI autenticamente native su macOS 26 Tahoe, isolamento completo dei crash/memoria MLX nel sottoprocesso e rilascio garantito di RAM/Metal a fine coda o cancellazione.

### DEC-012: Calcolo RAM di Sistema Allineato a Pico & Monitoraggio Attività (Formula A XNU)
- **Data:** 14 Novembre 2026
- **Contesto:** `SystemMemoryService.currentSnapshot()` utilizzava `active_count + wire_count + compressor_page_count` con `getpagesize()`, generando valori incoerenti rispetto a Monitoraggio Attività e a Pico.
- **Decisione:** Adottare la Formula A ufficiale XNU / Activity Monitor già validata in Pico (`App = internal_page_count - purgeable_count`, `Used = App + wire_count + compressor_page_count`) moltiplicata per `vm_kernel_page_size`.

### DEC-013: Isolamento `multiprocessing` in `WhisperEngine` e Logging Persistente su Disco
- **Data:** 14 Novembre 2026
- **Contesto:** I sottoprocessi `multiprocessing` spawnati in PyInstaller senza `freeze_support()` rieseguivano `main()` e intercettavano i comandi JSON da `stdin`, mentre i log in sola RAM si perdevano alla chiusura dell'app.
- **Decisione:** Chiamare `multiprocessing.freeze_support()` all'ingresso di `whisper_engine.py`, aggiungere una guardia sugli argomenti CLI imprevisti prima di leggere `stdin`, terminare sempre `processManager` su `fatal_error` in `AppState.swift` e scrivere ogni riga di log con timestamp in `~/Library/Logs/WhisperStudio/engine.log` (rotazione a 512 KB).

### DEC-014: Design System Unificato "Apple Squircle Concentrico" & Vincolo Formati di Esportazione
- **Data:** 14 Novembre 2026
- **Contesto:** L'interfaccia presentava raggi eterogenei (`5pt`, `8pt`, `9pt`, `10pt`, `16pt`, `Capsule`), divisori ridondanti in sidebar, due bottoni asimmetrici per il cambio modalità modello, e consentiva di deselezionare entrambi i formati di output.
- **Decisione:** Formalizzare [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) con scala concentrica (`12pt` card, `10pt` controlli/pulsanti, `7pt` cursori interni), introdurre `AppleSegmentedSwitch` per Modello e Lingua, sostituire le checkbox con card `AppleSwitchToggleStyle` ON/OFF e mutua attivazione automatica in `AppPreferences` (`setExportDocx` / `setExportTxt`), e convertire la conferma manuale in `.alert` nativo standard.

### DEC-015: Migrazione Runtime `WhisperEngine` a Python 3.12.16 (`arm64`) Isolato
- **Data:** 15 Novembre 2026
- **Contesto:** Il Python 3.9.6 di sistema (Xcode CLT) è End-of-Life e impedisce l'adozione delle versioni più recenti di `mlx`, `mlx-whisper` e `huggingface_hub`.
- **Decisione:** Creare un virtual environment dedicato in `macOS/Engine/.venv` (gestito via `uv`, già escluso da `.gitignore`) con Python 3.12.16 `arm64`, aggiornare `requirements-engine.txt` (includendo `pyinstaller>=6.10.0`) e puntare `Scripts/build_and_install_app.sh` a `$ENGINE_DIR/.venv/bin/pyinstaller` con stampa della versione Python usata in build.

### DEC-016: Filtri Anti-Ripetizione e Anti-Allucinazione in `WhisperEngine` (`mlx-whisper`)
- **Data:** 16 Novembre 2026
- **Contesto:** Su registrazioni con brusio di fondo (soprattutto con modello Turbo), Whisper può emettere ripetizioni consecutive di segmenti brevi identici (es. `"Grazie. Grazie. Grazie."`).
- **Decisione:** Passare `hallucination_silence_threshold=2.0` a `mlx_whisper.transcribe()` (unico tra i tre parametri Windows supportato nativamente dalla firma di `mlx_whisper.transcribe` / `DecodingOptions`, che non espone `repetition_penalty` né `no_repeat_ngram_size`) e applicare nel ciclo `for seg in segments` la deduplica dei segmenti brevi consecutivi identici (`<= 3` parole dopo `t.lower().strip(".,!?;:…\"'()[]{}")`).

### DEC-017: Soglia Modalità Automatica Alzata a ≥ 24 GB RAM Unificata
- **Data:** 16 Novembre 2026
- **Contesto:** Nei test comparativi con i nuovi filtri anti-ripetizione su registrazioni reali fino a 77 minuti, `Large-v3 Turbo` ha mostrato qualità praticamente allineata a `Large-v3 Standard` con ~2× velocità e consumo di memoria molto inferiore; su Mac da 16 GB la memoria unificata condivisa con macOS/GPU lascia poco margine a `Large-v3 Standard`.
- **Decisione:** Alzare la soglia automatica in `AppState.swift` (`activeModel`, `isModelWarningActualWarning`, `modelWarningMessage`) da `<= 8.5 GB` a `< 23.5 GB` (`≥ 24 GB` per `Large-v3 Standard`; `< 24 GB` — inclusi Mac da 8 GB e 16 GB — per `Large-v3 Turbo`), aggiornando le stringhe IT/EN (`Strings.swift`, `HelpGuideView.swift`) e mantenendo `Large-v3` sempre selezionabile in Modalità Manuale.
