import SwiftUI

struct UpdateDialogView: View {
    let info: AvailableUpdateInfo
    let lang: UILanguage
    let onDownload: () -> Void
    let onLater: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                appIconView
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(S.text("update_available_header", lang: lang))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.textTitle)

                    HStack(spacing: 6) {
                        Text("v\(AppConstants.version)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(AppTheme.textSecondary)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(info.displayTag)
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(AppTheme.emerald)
                    }
                }
                Spacer()
            }

            HStack(spacing: 6) {
                Text(S.text("update_changelog_title", lang: lang))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("(\(info.releaseName))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.indigo)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    markdownNotesView(info.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
            .frame(minHeight: 220, maxHeight: 260)
            .background(AppTheme.windowBg)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 10) {
                Button(action: onSkip) {
                    Text(S.text("btn_skip_version", lang: lang))
                        .font(.callout)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            Capsule()
                                .stroke(AppTheme.borderDashed, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Button(S.text("btn_update_later", lang: lang), action: onLater)
                    .buttonStyle(SolidRoundedButtonStyle(
                        background: AppTheme.buttonSecondaryBg,
                        hoverBackground: AppTheme.buttonSecondaryHover,
                        foreground: AppTheme.textPrimary,
                        borderColor: AppTheme.borderDashed,
                        cornerRadius: 9,
                        minHeight: 38
                    ))

                Button(action: onDownload) {
                    Label(S.text("btn_download_update", lang: lang), systemImage: "arrow.down.circle.fill")
                }
                .buttonStyle(SolidRoundedButtonStyle(
                    background: AppTheme.indigo,
                    hoverBackground: AppTheme.indigoHover,
                    cornerRadius: 9,
                    minHeight: 38
                ))
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 600)
        .background(AppTheme.sidebarBg)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var appIconView: some View {
        if let url = Bundle.main.url(forResource: "wispr", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }

    @ViewBuilder
    private func markdownNotesView(_ raw: String) -> some View {
        let lines = raw.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n", omittingEmptySubsequences: false)
        if lines.isEmpty || raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(lang == .it ? "Nessuna nota di rilascio fornita." : "No release notes provided.")
                .italic()
                .foregroundStyle(.secondary)
        } else {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, sub in
                let line = String(sub).trimmingCharacters(in: .whitespaces)
                if line.isEmpty {
                    Spacer().frame(height: 4)
                } else if line.hasPrefix("### ") {
                    renderInline(String(line.dropFirst(4)))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.indigo)
                        .padding(.top, 4)
                } else if line.hasPrefix("## ") {
                    renderInline(String(line.dropFirst(3)))
                        .font(.headline)
                        .foregroundStyle(Color(red: 16/255, green: 185/255, blue: 129/255))
                        .padding(.top, 6)
                } else if line.hasPrefix("# ") {
                    renderInline(String(line.dropFirst(2)))
                        .font(.title3.weight(.bold))
                        .padding(.top, 6)
                } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                    HStack(alignment: .top, spacing: 6) {
                        Text("•").foregroundStyle(.secondary)
                        renderInline(String(line.dropFirst(2)))
                    }
                } else {
                    renderInline(line)
                }
            }
        }
    }

    private func renderInline(_ text: String) -> Text {
        if let attr = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attr)
        }
        return Text(text)
    }
}
