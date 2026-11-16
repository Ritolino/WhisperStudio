import AppKit
import SwiftUI

struct LogsSheetView: View {
    @Bindable var state: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(S.text("logs_title", lang: state.lang))
                    .font(.headline)
                    .foregroundStyle(AppTheme.textTitle)
                Spacer()
                Button(S.text("logs_copy", lang: state.lang)) {
                    let joined = state.engineLogs.joined(separator: "\n")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(joined, forType: .string)
                }
                .buttonStyle(SolidRoundedButtonStyle(
                    background: AppTheme.buttonSecondaryBg,
                    hoverBackground: AppTheme.buttonSecondaryHover,
                    foreground: AppTheme.textPrimary,
                    borderColor: AppTheme.borderDashed,
                    cornerRadius: 8,
                    minHeight: 30
                ))
                .disabled(state.engineLogs.isEmpty)
            }

            ScrollView {
                if state.engineLogs.isEmpty {
                    Text(S.text("logs_empty", lang: state.lang))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                } else {
                    Text(state.engineLogs.joined(separator: "\n"))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(AppTheme.textPrimary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.windowBg)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack {
                Button(S.text("btn_clear", lang: state.lang)) {
                    state.clearLogs()
                }
                .buttonStyle(SolidRoundedButtonStyle(
                    background: AppTheme.buttonSecondaryBg,
                    hoverBackground: AppTheme.danger,
                    foreground: AppTheme.textPrimary,
                    borderColor: AppTheme.borderDashed,
                    hoverBorderColor: AppTheme.dangerHover,
                    cornerRadius: 8,
                    minHeight: 32
                ))
                .disabled(state.engineLogs.isEmpty)
                Spacer()
                Button(S.text("help_close", lang: state.lang)) {
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
        .frame(width: 660, height: 420)
        .background(AppTheme.sidebarBg)
        .preferredColorScheme(.dark)
    }
}
