# Whisper MacOS — Vision, Scope & Mission

## 1. Vision
Fornire agli utenti di macOS l'esperienza di trascrizione audio e video più veloce, elegante e integrata nell'ecosistema Apple. Una vera app "cittadina di prima classe" per macOS, priva di telemetria, browser incapsulati (Electron) o dipendenze cloud.

## 2. Mission
- Sfruttare al 100% l'architettura **Apple Silicon** (M1, M2, M3, M4, M5) tramite il framework **Apple MLX** (`mlx-whisper`), accedendo direttamente ai core GPU Metal e alla memoria unificata ad altissima banda passante.
- Offrire un'interfaccia grafica nativa per macOS 26 Tahoe (`SwiftUI` + `AppKit`, Design System *Apple Squircle Concentrico*), completa di:
  - Barre di avanzamento flat, switch a capsula a 2 vie e transizioni fisiche criticamente smorzate.
  - Indicatore grafico di memoria RAM e pressione in tempo reale (Formula A XNU / Monitoraggio Attività).
  - Pieno supporto nativo per la **Touch Bar** dei MacBook Pro (`NSTouchBar`).
  - Notifiche native nel Centro Notifiche di macOS con rivelazione automatica nel Finder.
- Gestire in modo intelligente i profili di memoria RAM:
  - Mac con ≥ 24 GB RAM: seleziona di default **Large-v3 Standard** per la massima precisione.
  - Mac con < 24 GB RAM (8 GB e 16 GB): seleziona di default **Large-v3 Turbo** per evitare pressione sulla memoria swap e garantire un'esecuzione fulminea (mantenendo `Large-v3` sempre selezionabile in Modalità Manuale).
- Rilasciare immediatamente e completamente la memoria RAM e Metal (`mx.clear_cache()`) non appena la coda termina o viene arrestata.

## 3. Formati & Esportazioni
- **Input supportati:** MP3, M4A, WAV, MP4, MOV, MKV, AAC, OGG, WEBM, FLAC, OPUS, ALAC, AIFF, WMA.
- **Output generati:** File di testo `.txt` e documenti formattati Microsoft Word `.docx` salvati accanto al file originale.
- **Denominazione intelligente:** Preservazione dei titoli personalizzati (es. `EGI 12 novembre.m4a` ➔ `Trascrizione EGI 12 novembre.docx`) e pulizia automatica delle registrazioni vocali con timestamp.
