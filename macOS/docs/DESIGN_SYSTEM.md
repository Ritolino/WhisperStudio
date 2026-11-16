# Whisper Studio (macOS) — Design System ("Apple Squircle Concentrico")

> Documento di riferimento visivo e geometrico per l'interfaccia nativa SwiftUI / AppKit di **Whisper Studio 3.0.5** (macOS 26+ Tahoe).

---

## 1. Corrente di Design & Principi
L'interfaccia adotta una singola grammatica visiva ispirata alle linee guida **Apple Continuity / macOS System Settings / Linear Dark**:
- **Coerenza geometrica concentrica**: ogni raggio di curvatura (`style: .continuous`) deriva da una scala fissa a 3 livelli.
- **Zero rumore visivo**: nessuna linea divisoria ridondante dove i contenitori hanno già un bordo proprio; gerarchia ottenuta tramite superfici Zinc scure e spaziatura verticale costante (`16pt`).
- **Movimento fisico criticamente smorzato**: tutte le transizioni interattive usano molle `dampingFraction: 1.0` (`response: 0.22–0.24s`), reattive senza rimbalzi artificiali.

---

## 2. Scala Geometrica (`AppTheme`)

| Livello | Token Swift | Raggio | Applicazione |
| :--- | :--- | :---: | :--- |
| **Card & Contenitori** | `AppTheme.cardRadius` | `12pt` | Card RAM, Card Modello (Auto/Manuale), Card Formati Esportazione, `QueueItemRow`, `emptyDropZone` |
| **Controlli & Pulsanti** | `AppTheme.controlRadius` | `10pt` | Tutti i bottoni (`SolidRoundedButtonStyle`), contenitore esterno `AppleSegmentedSwitch`, tracciato `AppleSwitchToggleStyle` (`36×20pt`) |
| **Elementi Concentrici Interni** | `AppTheme.innerControlRadius` | `7pt` | Cursore attivo interno a `AppleSegmentedSwitch` (`R_ext 10pt - padding 3pt = 7pt`), badge stato (`HIGH` / `CRITICAL`) |

---

## 3. Palette Superfici & Colori Semantici (`AppTheme.swift`)
- **Sfondo Finestra**: `#121214` (`windowBg`)
- **Sidebar / Barre Header & Dock**: `#18181b` (`sidebarBg`)
- **Pannelli & Controlli**: `#161618` (`panelBg`), `#1f1f23` (`cardWaitingBg`), `#222226` (`buttonToggleBg`)
- **Accento Primario**: Indaco `#818cf8` (`indigo` / hover `#6d78f5`)
- **Stati Semantici**:
  - Successo / Ottimale / Avvia: Smeraldo `#10b981` (`emerald`)
  - Avviso / Pausa / Modello Turbo su ≥ 24 GB: Ambra `#f59e0b` (`amber`)
  - Errore / Annulla / Rimozione Hover: Rosso `#ef4444` (`danger`)

---

## 4. Componenti UI Standardizzati
1. **`AppleSegmentedSwitch`**: controllo a 2 vie squircle (`10pt` esterno, `7pt` cursore interno) usato sia per **Modello (`Automatica | Manuale`)** sia per **Lingua Audio (`Italiano | Rileva Auto`)**.
2. **`AppleSwitchToggleStyle`**: interruttore ON/OFF stile macOS/iOS (`36×20pt`, pomello `16×16pt`) dentro card raggruppata `12pt` per i **Formati di Esportazione (`.docx` / `.txt`)**, con vincolo di **almeno un formato sempre attivo** (spegnendo l'unico formato attivo si accende automaticamente l'altro).
3. **`FlatProgressBar`**: barra di avanzamento piatta a capsula (`height: 6pt` in card RAM e righe coda, `10pt` nel dock inferiore), sempre vuota allo `0%`.
4. **Avvisi di sistema**: uso di `.alert` nativo standard di macOS (`.default` blu primario + `.cancel`) per conferme non distruttive come il passaggio a selezione manuale.
