import SwiftUI

struct ModelHeaderView: View {
    @Bindable var state: AppState

    private var lang: UILanguage { state.lang }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // App Title & Hardware Badge
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 10) {
                    if let icon = loadBundledIcon() {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(S.text("win_title", lang: lang))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.textTitle)
                        Text(S.text("sub_edition", lang: lang))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .font(.caption.weight(.medium))
                        .frame(width: 14, alignment: .leading)
                    Text(S.text("hw_label", lang: lang))
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(AppTheme.emerald)
            }

            // System RAM & Memory Pressure
            VStack(alignment: .leading, spacing: 8) {
                let snap = state.memorySnapshot
                let ratio = snap.totalGB > 0 ? min(1.0, max(0.0, snap.usedSystemGB / snap.totalGB)) : 0
                HStack(spacing: 6) {
                    Image(systemName: "memorychip")
                        .font(.caption)
                        .foregroundStyle(AppTheme.indigo)
                    Text("RAM: \(String(format: "%.1f", snap.usedSystemGB)) / \(Int(snap.totalGB.rounded())) GB")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    if snap.pressure != .normal {
                        Text(snap.pressure == .critical ? "CRITICAL" : "HIGH")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(snap.pressure == .critical ? AppTheme.danger.opacity(0.2) : AppTheme.amber.opacity(0.2))
                            .foregroundStyle(snap.pressure == .critical ? AppTheme.danger : AppTheme.amber)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.innerControlRadius, style: .continuous))
                    }
                }

                FlatProgressBar(
                    value: ratio,
                    total: 1.0,
                    tint: pressureTint(ratio: ratio, pressure: snap.pressure),
                    height: 6
                )
            }
            .padding(10)
            .background(AppTheme.panelBg)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(AppTheme.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))

            // Transcription Model Section
            VStack(alignment: .leading, spacing: 8) {
                Text(S.text("section_model", lang: lang))
                    .font(.caption2.weight(.semibold))
                    .tracking(0.5)
                    .foregroundStyle(AppTheme.textSecondary)

                AppleSegmentedSwitch(
                    leftTitle: S.text("mode_auto_short", lang: lang),
                    rightTitle: S.text("mode_manual_short", lang: lang),
                    isLeftSelected: !state.preferences.isManualModelMode,
                    onSelectLeft: { state.restoreAutomaticMode() },
                    onSelectRight: {
                        if !state.preferences.isManualModelMode {
                            state.requestSwitchToManualMode()
                        }
                    }
                )
                .disabled(state.isBusy)

                if !state.preferences.isManualModelMode {
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: state.activeModel == .standard ? "sparkles.rectangle.stack" : "bolt.fill")
                            .foregroundStyle(AppTheme.indigo)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(S.text(state.activeModel == .standard ? "model_large_title" : "model_turbo_title", lang: lang))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.textTitle)
                            Text(S.text(state.activeModel == .standard ? "btn_large_sub" : "btn_small_sub", lang: lang))
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.indigo)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardSelectedBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                            .stroke(AppTheme.indigo, lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        modelChoiceButton(
                            option: .standard,
                            title: S.text("btn_large", lang: lang),
                            subtitle: S.text("btn_large_sub", lang: lang),
                            icon: "sparkles.rectangle.stack"
                        )

                        modelChoiceButton(
                            option: .turbo,
                            title: S.text("btn_small", lang: lang),
                            subtitle: S.text("btn_small_sub", lang: lang),
                            icon: "bolt.fill"
                        )
                    }
                }

                if let warn = state.modelWarningMessage {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: state.isModelWarningActualWarning ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.caption2)
                            .padding(.top, 1)
                        Text(warn)
                            .font(.caption2.weight(.medium))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(state.isModelWarningActualWarning ? AppTheme.amber : AppTheme.emerald)
                }
            }

            // Audio Language Section (Unified Squircle Switch)
            VStack(alignment: .leading, spacing: 8) {
                Text(S.text("section_lang", lang: lang))
                    .font(.caption2.weight(.semibold))
                    .tracking(0.5)
                    .foregroundStyle(AppTheme.textSecondary)

                AppleSegmentedSwitch(
                    leftTitle: S.text("btn_lang_primary", lang: lang),
                    rightTitle: S.text("btn_lang_auto", lang: lang),
                    isLeftSelected: state.preferences.audioLanguage == .primary,
                    onSelectLeft: { state.preferences.audioLanguage = .primary },
                    onSelectRight: { state.preferences.audioLanguage = .auto }
                )
                .disabled(state.isBusy)

                Text(S.text("lang_subtitle", lang: lang))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            // Export Formats Section (macOS System Settings Grouped Card)
            VStack(alignment: .leading, spacing: 8) {
                Text(S.text("section_formats", lang: lang))
                    .font(.caption2.weight(.semibold))
                    .tracking(0.5)
                    .foregroundStyle(AppTheme.textSecondary)

                VStack(spacing: 0) {
                    Toggle(isOn: Binding(
                        get: { state.preferences.exportDocx },
                        set: { state.preferences.setExportDocx($0) }
                    )) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.richtext")
                                .font(.caption)
                                .foregroundStyle(AppTheme.indigo)
                                .frame(width: 16)
                            Text(S.text("chk_docx", lang: lang))
                                .font(.callout)
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                    .toggleStyle(AppleSwitchToggleStyle())
                    .disabled(state.isBusy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)

                    Rectangle()
                        .fill(AppTheme.borderSubtle)
                        .frame(height: 1)

                    Toggle(isOn: Binding(
                        get: { state.preferences.exportTxt },
                        set: { state.preferences.setExportTxt($0) }
                    )) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.plaintext")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(width: 16)
                            Text(S.text("chk_txt", lang: lang))
                                .font(.callout)
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                    .toggleStyle(AppleSwitchToggleStyle())
                    .disabled(state.isBusy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                }
                .background(AppTheme.panelBg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))

                Text(S.text("formats_subtitle", lang: lang))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func modelChoiceButton(option: TranscriptionModelOption, title: String, subtitle: String, icon: String) -> some View {
        let selected = state.preferences.selectedManualModel == option
        Button {
            state.preferences.selectedManualModel = option
        } label: {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(selected ? AppTheme.indigo : AppTheme.textSecondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selected ? AppTheme.textTitle : AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.indigo)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? AppTheme.cardSelectedBg : AppTheme.cardWaitingBg)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(selected ? AppTheme.indigo : AppTheme.borderCard, lineWidth: selected ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(state.isBusy)
    }

    private func pressureTint(ratio: Double, pressure: MemoryPressureLevel) -> Color {
        if pressure == .critical || ratio > 0.85 { return AppTheme.danger }
        if pressure == .warning || ratio > 0.70 { return AppTheme.amber }
        return AppTheme.indigo
    }

    private func loadBundledIcon() -> NSImage? {
        if let url = Bundle.main.url(forResource: "wispr", withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        return nil
    }
}
