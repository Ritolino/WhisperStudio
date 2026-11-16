import SwiftUI

struct QueueItemRow: View {
    let item: QueueItem
    let lang: UILanguage
    let canRemove: Bool
    let isHoveringRemove: Bool
    let onHoverRemove: (Bool) -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            statusIcon
                .font(.title3)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.fileName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(AppTheme.textTitle)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    statusBadge
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "internaldrive")
                            .font(.caption2)
                        Text(S.formatSize(item.fileSizeBytes))
                            .font(.caption.monospacedDigit())
                    }
                    .foregroundStyle(AppTheme.textSecondary)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(S.formatTime(item.durationSeconds))
                            .font(.caption.monospacedDigit())
                    }
                    .foregroundStyle(AppTheme.textSecondary)

                    if item.status == .running {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "stopwatch")
                                .font(.caption2)
                            Text(S.formatTime(item.elapsedSeconds))
                                .font(.caption.monospacedDigit())
                        }
                        .foregroundStyle(AppTheme.textPrimary)

                        HStack(spacing: 4) {
                            Image(systemName: "hourglass")
                                .font(.caption2)
                            Text("~\(S.formatTime(item.remainingSeconds))")
                                .font(.caption.monospacedDigit())
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                    } else if item.status == .error, let err = item.errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(AppTheme.danger)
                            .lineLimit(1)
                    }
                }

                if item.status == .running {
                    FlatProgressBar(
                        value: Double(item.progressPercent),
                        total: 100.0,
                        tint: AppTheme.indigo,
                        height: 6
                    )
                }
            }

            if item.status == .completed && !item.outputPaths.isEmpty {
                Button {
                    FinderService.revealInFinder(item.outputPaths)
                } label: {
                    Image(systemName: "folder")
                        .foregroundStyle(AppTheme.emerald)
                }
                .buttonStyle(.borderless)
                .help(S.text("card_reveal", lang: lang))
            }

            if canRemove {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(isHoveringRemove ? AppTheme.danger : AppTheme.textSecondary)
                        .animation(.easeInOut(duration: 0.15), value: isHoveringRemove)
                }
                .buttonStyle(.borderless)
                .onHover { hovering in
                    onHoverRemove(hovering)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .waiting:
            Image(systemName: "waveform")
                .foregroundStyle(AppTheme.textSecondary)
        case .downloadingModel, .loadingModel:
            ProgressView()
                .controlSize(.small)
                .tint(item.status == .downloadingModel ? AppTheme.amber : AppTheme.indigo)
        case .running:
            Image(systemName: "waveform.circle.fill")
                .foregroundStyle(AppTheme.indigo)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.emerald)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.danger)
        case .cancelled:
            Image(systemName: "stop.circle.fill")
                .foregroundStyle(AppTheme.amber)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch item.status {
        case .waiting:
            Text(S.text("card_waiting", lang: lang))
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
        case .downloadingModel:
            Text(S.text("card_downloading", lang: lang))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.amber)
        case .loadingModel:
            Text(S.text("tb_loading", lang: lang))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.indigo)
        case .running:
            Text("\(item.progressPercent)%")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(AppTheme.indigo)
        case .completed:
            Text(S.text("card_completed", lang: lang))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.emerald)
        case .error:
            Text(S.text("card_error", lang: lang))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.danger)
        case .cancelled:
            Text(S.text("card_cancelled", lang: lang))
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.amber)
        }
    }

    private var cardBackground: Color {
        switch item.status {
        case .running, .loadingModel, .downloadingModel:
            return AppTheme.cardRunningBg
        case .completed:
            return AppTheme.cardDoneBg
        case .error:
            return AppTheme.cardErrorBg
        case .cancelled:
            return AppTheme.cardCancelledBg
        case .waiting:
            return AppTheme.cardWaitingBg
        }
    }

    private var borderColor: Color {
        switch item.status {
        case .running, .loadingModel, .downloadingModel:
            return AppTheme.indigo
        case .completed:
            return AppTheme.emerald
        case .error:
            return AppTheme.danger
        case .cancelled:
            return AppTheme.amber
        case .waiting:
            return AppTheme.borderCard
        }
    }

    private var borderWidth: CGFloat {
        switch item.status {
        case .waiting: return 1
        default: return 1.5
        }
    }
}
