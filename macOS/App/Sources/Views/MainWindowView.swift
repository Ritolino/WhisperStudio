import SwiftUI
import UniformTypeIdentifiers

@Observable
private final class QueueReorderState {
    var draggedItemID: UUID?
    var dropTargetIndex: Int?
    var hoveredRemoveID: UUID?
}

struct MainWindowView: View {
    @Bindable var state: AppState
    private let reorderState = QueueReorderState()

    private var lang: UILanguage { state.lang }

    var body: some View {
        HStack(spacing: 0) {
            sidebarView
            Rectangle()
                .fill(AppTheme.borderSubtle)
                .frame(width: 1)
            rightPanelView
        }
        .frame(minWidth: 940, minHeight: 620)
        .background(AppTheme.windowBg)
        .preferredColorScheme(.dark)
        .alert(item: $state.activeAlert) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(
            S.text("dlg_manual_title", lang: lang),
            isPresented: $state.showManualConfirm
        ) {
            Button(S.text("dlg_manual_confirm", lang: lang)) {
                state.confirmSwitchToManualMode()
            }
            Button(S.text("dlg_manual_cancel", lang: lang), role: .cancel) {}
        } message: {
            Text(S.text("dlg_manual_msg", lang: lang))
        }
        .sheet(item: $state.availableUpdate) { updateInfo in
            UpdateDialogView(
                info: updateInfo,
                lang: lang,
                onDownload: { state.downloadUpdate(updateInfo) },
                onLater: { state.postponeUpdate(updateInfo) },
                onSkip: { state.skipUpdate(updateInfo) }
            )
        }
        .sheet(isPresented: $state.showHelpSheet) {
            HelpGuideView(lang: lang)
        }
        .sheet(isPresented: $state.showLogsSheet) {
            LogsSheetView(state: state)
        }
    }

    @ViewBuilder
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                ModelHeaderView(state: state)
                    .padding(18)
            }

            Spacer(minLength: 8)
            Rectangle()
                .fill(AppTheme.borderSubtle)
                .frame(height: 1)

            HStack {
                Text(S.text("footer", lang: lang))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .frame(width: 295)
        .background(AppTheme.sidebarBg)
    }

    @ViewBuilder
    private var rightPanelView: some View {
        VStack(spacing: 0) {
            queueHeaderBar
            Rectangle()
                .fill(AppTheme.borderSubtle)
                .frame(height: 1)
            queueContentArea
            Rectangle()
                .fill(AppTheme.borderSubtle)
                .frame(height: 1)
            bottomDockView
        }
        .background(AppTheme.windowBg)
    }

    @ViewBuilder
    private var queueHeaderBar: some View {
        HStack(spacing: 10) {
            Text(S.text("queue_title", lang: lang))
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textTitle)

            Text("(\(state.queue.count))")
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(AppTheme.indigo)

            Spacer()

            Button {
                state.pickAndAddFiles()
            } label: {
                Label(S.text("btn_add", lang: lang), systemImage: "plus")
            }
            .buttonStyle(SolidRoundedButtonStyle(
                background: AppTheme.indigo,
                hoverBackground: AppTheme.indigoHover,
                cornerRadius: AppTheme.controlRadius,
                minHeight: 32,
                horizontalPadding: 14
            ))

            Button {
                state.clearQueue()
            } label: {
                Label(S.text("btn_clear", lang: lang), systemImage: "trash")
            }
            .buttonStyle(SolidRoundedButtonStyle(
                background: AppTheme.buttonSecondaryBg,
                hoverBackground: AppTheme.danger,
                foreground: AppTheme.textPrimary,
                borderColor: AppTheme.borderCard,
                hoverBorderColor: AppTheme.dangerHover,
                cornerRadius: AppTheme.controlRadius,
                minHeight: 32,
                horizontalPadding: 14
            ))
            .disabled(state.queue.isEmpty || state.isBusy)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(AppTheme.sidebarBg)
    }

    @ViewBuilder
    private var queueContentArea: some View {
        ZStack {
            if state.queue.isEmpty {
                emptyDropZone
            } else {
                queueListView
            }

            if state.isDropTargeted {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppTheme.indigo, style: StrokeStyle(lineWidth: 2.5, dash: [8]))
                    .background(AppTheme.indigo.opacity(0.08).clipShape(RoundedRectangle(cornerRadius: 14)))
                    .padding(14)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: $state.isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    @ViewBuilder
    private var queueListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(state.queue.enumerated()), id: \.element.id) { index, item in
                    queueRowContent(index: index, item: item)
                }

                // Bottom drop zone so dropping below the last item always snaps to the end
                Color.clear
                    .frame(height: 36)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .dropDestination(for: String.self) { droppedItems, _ in
                        performQueueDrop(droppedItems, targetIndex: state.queue.count)
                    } isTargeted: { targeted in
                        updateDropTarget(targeted: targeted, index: state.queue.count)
                    }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private func queueRowContent(index: Int, item: QueueItem) -> some View {
        let canRemove = !(state.isBusy && (item.status == .running || item.status == .downloadingModel || item.status == .loadingModel))
        let baseRow = QueueItemRow(
            item: item,
            lang: lang,
            canRemove: canRemove,
            isHoveringRemove: reorderState.hoveredRemoveID == item.id,
            onHoverRemove: { hovering in
                if hovering {
                    reorderState.hoveredRemoveID = item.id
                } else if reorderState.hoveredRemoveID == item.id {
                    reorderState.hoveredRemoveID = nil
                }
            },
            onRemove: { state.removeItem(item.id) }
        )
        .padding(.vertical, 4)
        .background(
            VStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .dropDestination(for: String.self) { droppedItems, _ in
                        performQueueDrop(droppedItems, targetIndex: index)
                    } isTargeted: { targeted in
                        updateDropTarget(targeted: targeted, index: index)
                    }

                Color.clear
                    .contentShape(Rectangle())
                    .dropDestination(for: String.self) { droppedItems, _ in
                        performQueueDrop(droppedItems, targetIndex: index + 1)
                    } isTargeted: { targeted in
                        updateDropTarget(targeted: targeted, index: index + 1)
                    }
            }
        )
        .overlay(alignment: .top) {
            if shouldShowInsertionLine(at: index) {
                insertionIndicatorLine
                    .offset(y: -3)
            }
        }
        .overlay(alignment: .bottom) {
            if index == state.queue.count - 1 && shouldShowInsertionLine(at: state.queue.count) {
                insertionIndicatorLine
                    .offset(y: 3)
            }
        }

        if canMoveItem(item) {
            baseRow.draggable(item.id.uuidString) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundStyle(AppTheme.indigo)
                    Text(item.fileName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.textTitle)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(width: 220, alignment: .leading)
                .background(AppTheme.cardRunningBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppTheme.indigo, lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .onAppear {
                    reorderState.draggedItemID = item.id
                }
            }
        } else {
            baseRow
        }
    }

    private func canMoveItem(_ item: QueueItem) -> Bool {
        !state.isBusy || item.status == .waiting
    }

    private var minReorderDropIndex: Int {
        guard state.isBusy else { return 0 }
        return (state.queue.lastIndex(where: { $0.status != .waiting }).map { $0 + 1 }) ?? 0
    }

    private var insertionIndicatorLine: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(AppTheme.indigo)
                .frame(width: 7, height: 7)
            Rectangle()
                .fill(AppTheme.indigo)
                .frame(height: 2)
        }
        .padding(.horizontal, 4)
        .allowsHitTesting(false)
    }

    private func shouldShowInsertionLine(at index: Int) -> Bool {
        guard reorderState.dropTargetIndex == index else { return false }
        if state.isBusy && index < minReorderDropIndex {
            return false
        }
        if let draggedID = reorderState.draggedItemID,
           let draggedIdx = state.queue.firstIndex(where: { $0.id == draggedID }),
           (index == draggedIdx || index == draggedIdx + 1) {
            return false
        }
        return true
    }

    private func updateDropTarget(targeted: Bool, index: Int) {
        if targeted {
            reorderState.dropTargetIndex = index
        } else if reorderState.dropTargetIndex == index {
            reorderState.dropTargetIndex = nil
        }
    }

    private func performQueueDrop(_ droppedItems: [String], targetIndex: Int) -> Bool {
        reorderState.dropTargetIndex = nil
        defer { reorderState.draggedItemID = nil }
        guard let raw = droppedItems.first,
              let draggedUUID = UUID(uuidString: raw),
              let fromIndex = state.queue.firstIndex(where: { $0.id == draggedUUID }),
              canMoveItem(state.queue[fromIndex]) else {
            return false
        }
        let minIdx = minReorderDropIndex
        let clampedTarget = min(max(minIdx, targetIndex), state.queue.count)
        guard clampedTarget != fromIndex && clampedTarget != fromIndex + 1 else {
            return false
        }
        withAnimation(.spring(response: 0.25, dampingFraction: 1.0)) {
            state.moveQueueItems(from: IndexSet(integer: fromIndex), to: clampedTarget)
        }
        return true
    }

    @ViewBuilder
    private var bottomDockView: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    Text(state.statusMessage)
                        .font(.callout)
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()

                    if !state.isBusy && !state.queue.isEmpty {
                        let totalBytes = state.queue.reduce(Int64(0)) { $0 + $1.fileSizeBytes }
                        let totalDur = state.queue.reduce(0.0) { $0 + $1.durationSeconds }
                        HStack(spacing: 4) {
                            Image(systemName: "internaldrive")
                                .font(.caption2)
                            Text(S.formatSize(totalBytes))
                                .font(.caption.monospacedDigit())
                        }
                        .foregroundStyle(AppTheme.textSecondary)

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(S.formatTime(totalDur))
                                .font(.caption.monospacedDigit())
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                    }

                    if state.isBusy && !state.isDownloadingModel && (state.totalElapsedSeconds > 0 || state.totalRemainingSeconds > 0) {
                        HStack(spacing: 4) {
                            Image(systemName: "stopwatch")
                                .font(.caption2)
                            Text(S.formatTime(state.totalElapsedSeconds))
                                .font(.caption.monospacedDigit())
                        }
                        .foregroundStyle(AppTheme.textPrimary)

                        HStack(spacing: 4) {
                            Image(systemName: "hourglass")
                                .font(.caption2)
                            Text("~\(S.formatTime(state.totalRemainingSeconds))")
                                .font(.caption.monospacedDigit())
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                    }

                    if state.isBusy || state.totalProgressPercent > 0 {
                        Text("\(state.totalProgressPercent)%")
                            .font(.callout.weight(.semibold).monospacedDigit())
                            .foregroundStyle(AppTheme.indigo)
                    }
                }

                FlatProgressBar(
                    value: Double(state.totalProgressPercent),
                    total: 100.0,
                    tint: AppTheme.indigo,
                    height: 10
                )
            }

            HStack(spacing: 12) {
                if state.isBusy {
                    if state.isDownloadingModel {
                        Button {
                            state.pauseModelDownload()
                        } label: {
                            Label(S.text("btn_pause_download", lang: lang), systemImage: "pause.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SolidRoundedButtonStyle(
                            background: AppTheme.amberDark,
                            hoverBackground: AppTheme.amberDarkHover,
                            cornerRadius: AppTheme.controlRadius,
                            minHeight: 44
                        ))
                        .disabled(state.runState == .stopping)
                    } else {
                        Button {
                            state.togglePause()
                        } label: {
                            Label(
                                S.text(state.runState == .paused ? "btn_resume" : "btn_pause", lang: lang),
                                systemImage: state.runState == .paused ? "play.fill" : "pause.fill"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SolidRoundedButtonStyle(
                            background: state.runState == .paused ? AppTheme.emerald : AppTheme.amberDark,
                            hoverBackground: state.runState == .paused ? AppTheme.emeraldHover : AppTheme.amberDarkHover,
                            cornerRadius: AppTheme.controlRadius,
                            minHeight: 44
                        ))
                        .disabled(state.runState == .stopping || state.runState == .starting)
                    }

                    Button {
                        state.cancelTranscription()
                    } label: {
                        Label(
                            S.text(state.isDownloadingModel ? "btn_cancel_download" : "btn_cancel", lang: lang),
                            systemImage: "stop.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SolidRoundedButtonStyle(
                        background: AppTheme.danger,
                        hoverBackground: AppTheme.dangerHover,
                        cornerRadius: AppTheme.controlRadius,
                        minHeight: 44
                    ))
                    .disabled(state.runState == .stopping)
                } else if !state.isActiveModelCached {
                    Button {
                        state.startModelDownload()
                    } label: {
                        Label(S.text("btn_download_model", lang: lang), systemImage: "arrow.down.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SolidRoundedButtonStyle(
                        background: AppTheme.indigo,
                        hoverBackground: AppTheme.indigoHover,
                        cornerRadius: AppTheme.controlRadius,
                        minHeight: 44
                    ))
                } else {
                    Button {
                        state.startTranscription()
                    } label: {
                        Label(S.text("btn_start", lang: lang), systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SolidRoundedButtonStyle(
                        background: AppTheme.emerald,
                        hoverBackground: AppTheme.emeraldHover,
                        cornerRadius: AppTheme.controlRadius,
                        minHeight: 44
                    ))
                    .disabled(state.queue.isEmpty)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppTheme.sidebarBg)
    }

    @ViewBuilder
    private var emptyDropZone: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.badge.plus")
                .font(.system(size: 42))
                .foregroundStyle(AppTheme.indigo)

            Text(S.text("empty_title", lang: lang))
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textTitle)

            Text(S.text("empty_subtitle", lang: lang))
                .font(.callout)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(36)
        .frame(maxWidth: 460)
        .background(AppTheme.dropZoneBg)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .strokeBorder(AppTheme.borderDashed, style: StrokeStyle(lineWidth: 1.5, dash: [6]))
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .padding(24)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var accepted = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            accepted = true
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                var resolvedURL: URL?
                if let rawData = data as? Data,
                   let str = String(data: rawData, encoding: .utf8) {
                    resolvedURL = URL(string: str)
                } else if let url = data as? URL {
                    resolvedURL = url
                } else if let nsurl = data as? NSURL {
                    resolvedURL = nsurl as URL
                }
                if let url = resolvedURL {
                    Task { @MainActor in
                        state.addDroppedOrPickedURLs([url])
                    }
                }
            }
        }
        return accepted
    }
}
