# Whisper Windows — Vision, Scope & Mission

## 1. Vision
Offrire agli utenti Windows la suite di trascrizione locale e autonoma più performante ed essenziale, capace di sfruttare al massimo sia le potenti GPU dedicate NVIDIA RTX/GTX (CUDA) sia i moderni processori multithread Intel e AMD.

## 2. Mission
- **Portabilità Assoluta:** Fornire un pacchetto standalone portatile (`WhisperStudio.exe`) che non richiede Python preinstallato né l'installazione manuale del massiccio NVIDIA CUDA Toolkit da 3+ GB.
- **Integrazione Dinamica CUDA 12:** Precaricare a livello di processo le librerie di calcolo ad alte prestazioni `cublasLt64_12.dll` e `cublas64_12.dll` per garantire inferenza GPU immediata in virgola mobile a mezza precisione (`float16`).
- **Fallback Trasparente su CPU:** In assenza di GPU NVIDIA dedicata (o con VRAM < 6 GB), passare istantaneamente alla CPU in multithreading sfruttando la quantizzazione ad interi `int8`.
- **Riconoscimento Vocale VAD & Anti-Allucinazioni:** Integrare Silero VAD (`vad_filter=True`) e disattivare il condizionamento precedente (`condition_on_previous_text=False`) per prevenire loop e blocchi.
- **Bilinguismo Nativo:** UI bilingue (Italiano e Inglese) con rendering vettoriale personalizzato delle bandiere emoji ad alta risoluzione (superando il limite di Windows che mostra le bandiere come lettere separate 'IT' o 'GB').

## 3. Formati & Esportazioni
- **Input:** MP3, WAV, M4A, AAC, MP4, MKV, FLAC, OGG, WEBM, MOV, WMA, ALAC, OPUS.
- **Output:** Testo `.txt` e Microsoft Word `.docx` con protezione dal file locking (auto-incremento del nome se il documento è aperto in Word).
- **Denominazione Intelligente:** Preservazione automatica dei titoli personalizzati come `EGI` e formattazione elegante delle date.
