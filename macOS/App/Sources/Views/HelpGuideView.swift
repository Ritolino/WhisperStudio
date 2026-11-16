import SwiftUI

struct HelpGuideView: View {
    let lang: UILanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(S.text("help_title", lang: lang))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textTitle)
                Spacer()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if lang == .it {
                        guideSection(
                            title: "Whisper Studio 3.0 — Architettura Nativa SwiftUI + MLX",
                            color: .indigo,
                            items: [
                                "Interfaccia nativa macOS Tahoe (SwiftUI + AppKit) con motore di trascrizione MLX isolato in un processo helper dedicato.",
                                "Al termine o all'annullamento di ogni coda, il processo helper termina restituendo immediatamente al sistema tutta la memoria MLX/Metal allocata.",
                                "Trascrizione 100% locale: file audio/video e documenti generati non lasciano mai il tuo Mac."
                            ]
                        )
                        guideSection(
                            title: "Gestione Modelli & Download",
                            color: .green,
                            items: [
                                "Modalità Automatica: seleziona Large-v3 Standard su Mac con ≥ 24 GB di RAM e Turbo su Mac da 8/16 GB o in caso di pressione memoria elevata.",
                                "Se il modello non è ancora stato scaricato, all'avvio viene mostrato il solo pulsante \"Annulla download\" per interrompere subito l'operazione."
                            ]
                        )
                        guideSection(
                            title: "Salvataggio & Coda",
                            color: .cyan,
                            items: [
                                "Scegli dove salvare da Impostazioni ➔ Salva trascrizioni in (Accanto al file originale, Cartella personalizzata o Chiedi ogni volta).",
                                "Salvataggio sicuro: se esistono già file con lo stesso nome, aggiunge (2), (3) senza sovrascriverli."
                            ]
                        )
                    } else {
                        guideSection(
                            title: "Whisper Studio 3.0 — Native SwiftUI + MLX Architecture",
                            color: .indigo,
                            items: [
                                "Native macOS Tahoe UI (SwiftUI + AppKit) paired with an isolated Python/MLX helper process.",
                                "When a batch completes or is cancelled, the helper exits cleanly so macOS immediately reclaims all MLX and Metal memory.",
                                "100% local transcription: your media files and documents never leave your Mac."
                            ]
                        )
                        guideSection(
                            title: "Model Management & Downloads",
                            color: .green,
                            items: [
                                "Automatic Mode: picks Large-v3 Standard on Macs with ≥ 24 GB RAM and switches to Turbo on 8/16 GB Macs or under elevated memory pressure.",
                                "When downloading a model for the first time, a dedicated \"Cancel download\" button lets you abort cleanly at any time."
                            ]
                        )
                        guideSection(
                            title: "Output Saving & Queue",
                            color: .cyan,
                            items: [
                                "Configure destination from Settings ➔ Save transcriptions to (Next to original file, Custom folder, or Ask every time).",
                                "Safe saving: if files with the same name already exist, (2), (3) are appended automatically without overwriting."
                            ]
                        )
                    }
                }
                .padding(14)
            }
            .background(AppTheme.windowBg)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                Spacer()
                Button(S.text("help_close", lang: lang)) {
                    dismiss()
                }
                .buttonStyle(SolidRoundedButtonStyle(
                    background: AppTheme.indigo,
                    hoverBackground: AppTheme.indigoHover,
                    cornerRadius: 8,
                    minHeight: 32
                ))
            }
        }
        .padding(20)
        .frame(width: 600, height: 440)
        .background(AppTheme.sidebarBg)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func guideSection(title: String, color: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(color)
            ForEach(items, id: \.self) { line in
                HStack(alignment: .top, spacing: 6) {
                    Text("•").foregroundStyle(AppTheme.textSecondary)
                    Text(line).font(.callout).foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
    }
}
