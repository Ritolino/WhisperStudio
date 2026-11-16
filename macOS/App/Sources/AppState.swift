import AppKit
import AVFoundation
import Foundation
import Observation

struct AlertPayload: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

@Observable
final class AppState {
    let preferences = AppPreferences()
    private let processManager = TranscriptionProcess()
    var touchBarController: TouchBarController?

    var queue: [QueueItem] = []
    var runState: EngineRunState = .idle {
        didSet { touchBarController?.refresh() }
    }
    var statusMessage: String = ""
    var totalProgressPercent: Int = 0 {
        didSet { touchBarController?.refresh() }
    }
    var totalElapsedSeconds: Double = 0
    var totalRemainingSeconds: Double = 0
    var currentFileIndex: Int = 0
    var totalBatchFiles: Int = 0

    var memorySnapshot: SystemMemorySnapshot = SystemMemoryService.currentSnapshot()
    var engineLogs: [String] = []
    var cachedModelRepos: Set<String> = []
    private(set) var isDownloadOnlyRun = false

    var showManualConfirm = false
    var showHelpSheet = false
    var showLogsSheet = false
    var activeAlert: AlertPayload?
    var availableUpdate: AvailableUpdateInfo?
    var isDropTargeted = false

    private var memoryTimer: Timer?
    private var sessionNotifiedVersions: Set<String> = []
    private var lastBatchFolderURL: URL?

    init() {
        statusMessage = S.text("status_ready", lang: preferences.uiLanguage)
        refreshModelCacheStatus()
        startMemoryPolling()
        scheduleAutoUpdateCheck()
    }

    var lang: UILanguage { preferences.uiLanguage }

    var activeModel: TranscriptionModelOption {
        if preferences.isManualModelMode {
            return preferences.selectedManualModel
        }
        if memorySnapshot.totalGB < 23.5 {
            return .turbo
        }
        if memorySnapshot.pressure != .normal {
            return .turbo
        }
        return .standard
    }

    var isActiveModelCached: Bool {
        cachedModelRepos.contains(activeModel.huggingFaceRepo)
    }

    func refreshModelCacheStatus() {
        var found: Set<String> = []
        for opt in TranscriptionModelOption.allCases where Self.isModelCachedLocally(repoId: opt.huggingFaceRepo) {
            found.insert(opt.huggingFaceRepo)
        }
        cachedModelRepos = found
    }

    private static func hfHubBaseDirectory() -> URL {
        let env = ProcessInfo.processInfo.environment
        if let customHub = env["HF_HUB_CACHE"], !customHub.isEmpty {
            return URL(fileURLWithPath: customHub)
        }
        if let customHome = env["HF_HOME"], !customHome.isEmpty {
            return URL(fileURLWithPath: customHome).appendingPathComponent("hub")
        }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".cache/huggingface/hub")
    }

    private static func isModelCachedLocally(repoId: String) -> Bool {
        let hubBase = hfHubBaseDirectory()
        let folderName = "models--" + repoId.replacingOccurrences(of: "/", with: "--")
        let snapshotsDir = hubBase.appendingPathComponent(folderName).appendingPathComponent("snapshots")
        guard let snapshots = try? FileManager.default.contentsOfDirectory(at: snapshotsDir, includingPropertiesForKeys: nil) else {
            return false
        }
        let weightNames = ["weights.safetensors", "weights.npz", "model.safetensors"]
        for snap in snapshots {
            let configPath = snap.appendingPathComponent("config.json").path
            guard FileManager.default.fileExists(atPath: configPath) else { continue }
            for w in weightNames {
                let wURL = snap.appendingPathComponent(w).resolvingSymlinksInPath()
                if let attrs = try? FileManager.default.attributesOfItem(atPath: wURL.path),
                   let size = attrs[.size] as? NSNumber,
                   size.int64Value > 10_000_000 {
                    return true
                }
            }
        }
        return false
    }

    private static func cleanupIncompleteModelCache(repoId: String) {
        let hubBase = hfHubBaseDirectory()
        let folderName = "models--" + repoId.replacingOccurrences(of: "/", with: "--")
        let modelDir = hubBase.appendingPathComponent(folderName)
        let fm = FileManager.default
        guard fm.fileExists(atPath: modelDir.path) else { return }

        // If the model isn't completely cached yet, remove the entire model cache folder to reclaim all partial space;
        // otherwise only delete stray .incomplete files in blobs/.
        if !isModelCachedLocally(repoId: repoId) {
            try? fm.removeItem(at: modelDir)
            return
        }
        let blobsDir = modelDir.appendingPathComponent("blobs")
        if let items = try? fm.contentsOfDirectory(at: blobsDir, includingPropertiesForKeys: nil) {
            for item in items where item.pathExtension == "incomplete" {
                try? fm.removeItem(at: item)
            }
        }
    }

    var isModelWarningActualWarning: Bool {
        let isUnder24GB = memorySnapshot.totalGB < 23.5
        if !preferences.isManualModelMode && memorySnapshot.pressure != .normal {
            return true
        }
        if activeModel == .standard && isUnder24GB {
            return true
        }
        if activeModel == .turbo && !isUnder24GB {
            return true
        }
        return false
    }

    var modelWarningMessage: String? {
        let isUnder24GB = memorySnapshot.totalGB < 23.5
        if !preferences.isManualModelMode && memorySnapshot.pressure != .normal {
            return S.text("warn_pressure", lang: lang)
        }
        switch activeModel {
        case .standard:
            return S.text(isUnder24GB ? "warn_large_lt24gb" : "warn_large_ge24gb", lang: lang)
        case .turbo:
            return S.text(isUnder24GB ? "warn_turbo_lt24gb" : "warn_turbo_ge24gb", lang: lang)
        }
    }

    var isBusy: Bool { runState != .idle }

    var isDownloadingModel: Bool {
        if case .downloadingModel = runState { return true }
        return false
    }

    // MARK: - System Memory Polling

    private func startMemoryPolling() {
        memorySnapshot = SystemMemoryService.currentSnapshot()
        memoryTimer?.invalidate()
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.memorySnapshot = SystemMemoryService.currentSnapshot()
            }
        }
    }

    // MARK: - Language & Settings

    func setUILanguage(_ newLang: UILanguage) {
        preferences.uiLanguage = newLang
        if runState == .idle && totalProgressPercent == 0 {
            statusMessage = S.text("status_ready", lang: newLang)
        }
        touchBarController?.refresh()
    }

    func requestSwitchToManualMode() {
        guard !isBusy else { return }
        showManualConfirm = true
    }

    func confirmSwitchToManualMode() {
        preferences.isManualModelMode = true
        showManualConfirm = false
    }

    func restoreAutomaticMode() {
        guard !isBusy else { return }
        preferences.isManualModelMode = false
    }

    func chooseCustomDestinationFolder() {
        if let dir = FinderService.pickDirectory(title: S.text("dlg_choose_dest_title", lang: lang)) {
            preferences.customDestinationPath = dir.path
            preferences.destinationMode = .custom
        }
    }

    // MARK: - Queue Import & Management

    func pickAndAddFiles() {
        let urls = FinderService.pickMediaFiles(title: S.text("menu_add_files", lang: lang))
        addDroppedOrPickedURLs(urls)
    }

    func pickAndAddFolder() {
        if let dir = FinderService.pickDirectory(title: S.text("menu_add_folder", lang: lang)) {
            addDroppedOrPickedURLs([dir])
        }
    }

    func addDroppedOrPickedURLs(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        Task {
            let expanded = await Task.detached(priority: .userInitiated) {
                Self.expandMediaURLs(urls)
            }.value

            var newlyAdded: [QueueItem] = []
            for url in expanded {
                if queue.contains(where: { $0.url.standardizedFileURL == url.standardizedFileURL }) {
                    continue
                }
                let size = Self.fileSize(at: url)
                let item = QueueItem(
                    id: UUID(),
                    url: url,
                    fileSizeBytes: size,
                    durationSeconds: 60.0
                )
                queue.append(item)
                newlyAdded.append(item)
            }
            touchBarController?.refresh()

            // Probe exact durations asynchronously
            for added in newlyAdded {
                let dur = await Self.probeDuration(for: added.url)
                if let idx = queue.firstIndex(where: { $0.id == added.id }) {
                    queue[idx].durationSeconds = dur
                }
            }

            // If a batch is actively running, dynamically notify helper of appended files
            if processManager.isRunning && !newlyAdded.isEmpty {
                let payloads = queue
                    .filter { item in newlyAdded.contains(where: { $0.id == item.id }) }
                    .map { EngineFilePayload(id: $0.id.uuidString, path: $0.url.path, duration: $0.durationSeconds) }
                processManager.sendAppendFiles(payloads)
            }
        }
    }

    func removeItem(_ id: UUID) {
        guard let idx = queue.firstIndex(where: { $0.id == id }) else { return }
        let st = queue[idx].status
        if isBusy && (st == .running || st == .downloadingModel || st == .loadingModel) { return }
        queue.remove(at: idx)
        if processManager.isRunning {
            processManager.sendRemoveFile(id: id)
        }
        if isBusy {
            totalBatchFiles = max(currentFileIndex, queue.filter { $0.status != .cancelled }.count)
            if runState == .transcribing {
                statusMessage = totalBatchFiles > 1 ? "\(currentFileIndex)/\(totalBatchFiles)" : S.text("status_resumed", lang: lang)
            }
        } else if queue.isEmpty {
            totalProgressPercent = 0
            totalElapsedSeconds = 0
            totalRemainingSeconds = 0
            currentFileIndex = 0
            totalBatchFiles = 0
            statusMessage = S.text("status_ready", lang: lang)
        }
        touchBarController?.refresh()
    }

    func moveQueueItems(from offsets: IndexSet, to destination: Int) {
        if !isBusy {
            queue.move(fromOffsets: offsets, toOffset: destination)
            return
        }
        guard !offsets.isEmpty,
              offsets.allSatisfy({ queue.indices.contains($0) && queue[$0].status == .waiting }) else {
            return
        }
        let minDestination = (queue.lastIndex(where: { $0.status != .waiting }).map { $0 + 1 }) ?? 0
        let clampedDestination = min(max(destination, minDestination), queue.count)
        queue.move(fromOffsets: offsets, toOffset: clampedDestination)
        if processManager.isRunning {
            let waitingIDs = queue.filter { $0.status == .waiting }.map(\.id)
            processManager.sendReorderFiles(orderedIDs: waitingIDs)
        }
    }

    func clearQueue() {
        guard !isBusy && !processManager.isRunning else {
            activeAlert = AlertPayload(
                title: S.text("dlg_clear_title", lang: lang),
                message: S.text("dlg_empty_msg", lang: lang)
            )
            return
        }
        queue.removeAll()
        totalProgressPercent = 0
        totalElapsedSeconds = 0
        totalRemainingSeconds = 0
        currentFileIndex = 0
        totalBatchFiles = 0
        statusMessage = S.text("status_ready", lang: lang)
        touchBarController?.refresh()
    }

    // MARK: - Transcription Execution

    func startModelDownload() {
        guard !isBusy && !processManager.isRunning else { return }
        isDownloadOnlyRun = true
        totalProgressPercent = 0
        totalElapsedSeconds = 0
        totalRemainingSeconds = 0
        currentFileIndex = 0
        totalBatchFiles = 0
        runState = .downloadingModel(percent: 0, message: S.text("status_downloading_model", lang: lang))
        statusMessage = S.text("status_downloading_model", lang: lang)

        let cmd = StartBatchCommand(
            cmd: "download_model",
            model_repo: activeModel.huggingFaceRepo,
            language: preferences.audioLanguage.engineCode(for: lang),
            formats: ["txt"],
            ui_lang: lang.rawValue,
            dest_dir: nil,
            files: []
        )

        appendLog("Starting model download for \(activeModel.huggingFaceRepo)")
        do {
            try processManager.start(
                command: cmd,
                onEvent: { [weak self] event in
                    self?.handleEngineEvent(event)
                },
                onLog: { [weak self] line in
                    self?.appendLog(line)
                },
                onTerminate: { [weak self] status in
                    self?.handleEngineTermination(exitCode: status)
                }
            )
        } catch {
            isDownloadOnlyRun = false
            runState = .idle
            statusMessage = error.localizedDescription
            activeAlert = AlertPayload(title: S.text("card_error", lang: lang), message: error.localizedDescription)
        }
    }

    func startTranscription() {
        guard !isBusy && !processManager.isRunning else { return }
        isDownloadOnlyRun = false

        guard !queue.isEmpty else {
            activeAlert = AlertPayload(
                title: S.text("dlg_empty_title", lang: lang),
                message: S.text("dlg_empty_msg", lang: lang)
            )
            return
        }

        var formats: [String] = []
        if preferences.exportDocx { formats.append("docx") }
        if preferences.exportTxt { formats.append("txt") }
        guard !formats.isEmpty else {
            activeAlert = AlertPayload(
                title: S.text("dlg_formats_title", lang: lang),
                message: S.text("dlg_formats_msg", lang: lang)
            )
            return
        }

        let resolvedDestDir: String?
        switch preferences.destinationMode {
        case .source:
            resolvedDestDir = nil
        case .custom:
            let path = preferences.customDestinationPath
            var isDir: ObjCBool = false
            guard !path.isEmpty,
                  FileManager.default.fileExists(atPath: path, isDirectory: &isDir),
                  isDir.boolValue,
                  FileManager.default.isWritableFile(atPath: path) else {
                activeAlert = AlertPayload(
                    title: S.text("err_dest_invalid_title", lang: lang),
                    message: String(format: S.text("err_dest_invalid_msg", lang: lang), path)
                )
                return
            }
            resolvedDestDir = path
        case .ask:
            guard let picked = FinderService.pickDirectory(title: S.text("dlg_choose_dest_title", lang: lang)) else {
                return
            }
            resolvedDestDir = picked.path
        }

        // If every item is completed, reset them all to waiting for a fresh pass
        let hasPending = queue.contains { $0.status != .completed }
        for idx in queue.indices {
            if !hasPending || queue[idx].status != .completed {
                queue[idx].status = .waiting
                queue[idx].progressPercent = 0
                queue[idx].elapsedSeconds = 0
                queue[idx].remainingSeconds = 0
                queue[idx].errorMessage = nil
                queue[idx].outputPaths = []
            }
        }

        let filesToProcess = queue
            .filter { $0.status == .waiting }
            .map { EngineFilePayload(id: $0.id.uuidString, path: $0.url.path, duration: $0.durationSeconds) }

        guard !filesToProcess.isEmpty else { return }

        totalProgressPercent = 0
        totalElapsedSeconds = 0
        totalRemainingSeconds = 0
        currentFileIndex = 0
        totalBatchFiles = filesToProcess.count
        lastBatchFolderURL = resolvedDestDir.map { URL(fileURLWithPath: $0) }
        runState = .starting
        statusMessage = S.text("status_loading_model", lang: lang)

        let cmd = StartBatchCommand(
            model_repo: activeModel.huggingFaceRepo,
            language: preferences.audioLanguage.engineCode(for: lang),
            formats: formats,
            ui_lang: lang.rawValue,
            dest_dir: resolvedDestDir,
            files: filesToProcess
        )

        appendLog("Starting WhisperEngine for \(filesToProcess.count) file(s) with model \(activeModel.huggingFaceRepo)")

        do {
            try processManager.start(
                command: cmd,
                onEvent: { [weak self] event in
                    self?.handleEngineEvent(event)
                },
                onLog: { [weak self] line in
                    self?.appendLog(line)
                },
                onTerminate: { [weak self] status in
                    self?.handleEngineTermination(exitCode: status)
                }
            )
        } catch {
            runState = .idle
            statusMessage = error.localizedDescription
            activeAlert = AlertPayload(title: S.text("card_error", lang: lang), message: error.localizedDescription)
        }
    }

    func togglePause() {
        switch runState {
        case .transcribing:
            processManager.sendPause()
            runState = .paused
            statusMessage = S.text("status_paused", lang: lang)
        case .paused:
            processManager.sendResume()
            runState = .transcribing
            statusMessage = S.text("status_resumed", lang: lang)
        default:
            break
        }
    }

    func pauseModelDownload() {
        guard isBusy, isDownloadingModel else { return }
        isDownloadOnlyRun = false
        runState = .stopping
        processManager.cancelWithTimeout(ms: 800)
        runState = .idle
        totalProgressPercent = 0
        statusMessage = S.text("status_download_paused", lang: lang)
    }

    func cancelTranscription() {
        guard isBusy else { return }
        let wasDownloading = isDownloadingModel
        let repoToClean = activeModel.huggingFaceRepo
        isDownloadOnlyRun = false
        runState = .stopping
        statusMessage = S.text("status_cancelling", lang: lang)
        processManager.cancelWithTimeout(ms: 800)

        if wasDownloading {
            finalizeCancelledUI()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(450))
                Self.cleanupIncompleteModelCache(repoId: repoToClean)
                refreshModelCacheStatus()
            }
        }
    }

    // MARK: - Engine Events

    private func handleEngineEvent(_ ev: RawEngineEvent) {
        if runState == .idle {
            return
        }
        switch ev.event {
        case "model_cached_status":
            if ev.cached == true, let repo = ev.repo {
                cachedModelRepos.insert(repo)
            } else if ev.cached == false, let repo = ev.repo {
                cachedModelRepos.remove(repo)
            }
            if ev.cached == false {
                runState = .downloadingModel(percent: 0, message: S.text("status_downloading_model", lang: lang))
                statusMessage = S.text("status_downloading_model", lang: lang)
            } else {
                runState = .starting
                statusMessage = S.text("status_loading_model", lang: lang)
            }

        case "download_progress":
            let p = ev.percent ?? 0
            let msg = ev.message ?? S.text("status_downloading_model", lang: lang)
            runState = .downloadingModel(percent: p, message: msg)
            totalProgressPercent = p
            statusMessage = msg

        case "model_ready":
            refreshModelCacheStatus()
            if runState != .stopping && !isDownloadOnlyRun {
                runState = .transcribing
                statusMessage = S.text("status_loading_model", lang: lang)
            }

        case "file_started":
            currentFileIndex = ev.index ?? currentFileIndex
            totalBatchFiles = ev.total ?? totalBatchFiles
            if let idStr = ev.id, let uuid = UUID(uuidString: idStr),
               let idx = queue.firstIndex(where: { $0.id == uuid }) {
                queue[idx].status = .running
                queue[idx].progressPercent = 0
            }

        case "file_progress":
            if let idStr = ev.id, let uuid = UUID(uuidString: idStr),
               let idx = queue.firstIndex(where: { $0.id == uuid }) {
                queue[idx].progressPercent = ev.file_percent ?? queue[idx].progressPercent
                queue[idx].elapsedSeconds = ev.file_elapsed ?? 0
                queue[idx].remainingSeconds = ev.file_remaining ?? 0
            }
            totalProgressPercent = ev.total_percent ?? totalProgressPercent
            totalElapsedSeconds = ev.total_elapsed ?? totalElapsedSeconds
            totalRemainingSeconds = ev.total_remaining ?? totalRemainingSeconds

            if runState != .paused && runState != .stopping {
                if totalBatchFiles > 1 {
                    statusMessage = "\(currentFileIndex)/\(totalBatchFiles)"
                } else {
                    statusMessage = S.text("status_resumed", lang: lang)
                }
            }

        case "file_completed":
            if let idStr = ev.id, let uuid = UUID(uuidString: idStr),
               let idx = queue.firstIndex(where: { $0.id == uuid }) {
                queue[idx].status = .completed
                queue[idx].progressPercent = 100
                queue[idx].outputPaths = (ev.outputs ?? []).map { URL(fileURLWithPath: $0) }
                if lastBatchFolderURL == nil, let firstOut = queue[idx].outputPaths.first {
                    lastBatchFolderURL = firstOut.deletingLastPathComponent()
                }
            }

        case "file_error":
            if let idStr = ev.id, let uuid = UUID(uuidString: idStr),
               let idx = queue.firstIndex(where: { $0.id == uuid }) {
                queue[idx].status = .error
                queue[idx].errorMessage = ev.error
            }
            if let err = ev.error {
                appendLog("File error: \(err)")
            }

        case "batch_completed":
            let count = ev.completed_count ?? 0
            let outFolder = ev.last_output_dir.flatMap { $0.isEmpty ? nil : URL(fileURLWithPath: $0) } ?? lastBatchFolderURL
            finalizeCompletedUI(count: count, outputFolder: outFolder)

        case "batch_cancelled":
            finalizeCancelledUI()

        case "fatal_error":
            let err = ev.error ?? "Unknown engine error"
            appendLog("Fatal error: \(err)")
            if runState == .stopping {
                finalizeCancelledUI()
            } else {
                processManager.cancelWithTimeout(ms: 800)
                finalizeCancelledUI(errorMessage: err)
            }

        default:
            break
        }
    }

    private func handleEngineTermination(exitCode: Int32) {
        appendLog("WhisperEngine exited with code \(exitCode)")
        if runState != .idle {
            if runState == .stopping {
                finalizeCancelledUI()
            } else {
                // Helper terminated unexpectedly
                for idx in queue.indices where queue[idx].status == .running {
                    queue[idx].status = .error
                    queue[idx].errorMessage = "Engine process terminated (code \(exitCode))"
                }
                runState = .idle
                statusMessage = S.text("cancelled_msg", lang: lang)
            }
        }
    }

    private func finalizeCompletedUI(count: Int, outputFolder: URL?) {
        let wasDownloadOnly = isDownloadOnlyRun
        isDownloadOnlyRun = false
        refreshModelCacheStatus()
        runState = .idle
        totalProgressPercent = count > 0 ? 100 : 0
        statusMessage = wasDownloadOnly
            ? S.text("status_ready", lang: lang)
            : String(format: S.text("finished_msg", lang: lang), count)

        if count > 0 {
            let body = String(format: S.text("notif_completed", lang: lang), count)
            NotificationService.shared.notifyBatchCompleted(
                title: "Whisper Studio",
                body: body,
                outputFolder: outputFolder
            )
            if let folder = outputFolder, FileManager.default.fileExists(atPath: folder.path) {
                FinderService.openFolder(folder)
            }
        }
    }

    private func finalizeCancelledUI(errorMessage: String? = nil) {
        for idx in queue.indices where queue[idx].status == .running {
            queue[idx].status = .waiting
            queue[idx].progressPercent = 0
            queue[idx].elapsedSeconds = 0
            queue[idx].remainingSeconds = 0
        }
        runState = .idle
        totalProgressPercent = 0
        statusMessage = errorMessage ?? S.text("cancelled_msg", lang: lang)
        if let errorMessage {
            activeAlert = AlertPayload(title: S.text("card_error", lang: lang), message: errorMessage)
        }
    }

    // MARK: - GitHub Updates

    private func scheduleAutoUpdateCheck() {
        Task {
            try? await Task.sleep(for: .seconds(10))
            await checkForUpdates(isManual: false)
        }
    }

    func checkForUpdates(isManual: Bool) async {
        let now = Date().timeIntervalSince1970
        if !isManual {
            guard preferences.autoCheckUpdates else { return }
            if (now - preferences.lastUpdateCheckTimestamp) < 86400 {
                return
            }
        }

        let outcome = await UpdateCheckerService.checkLatestRelease(
            currentVersion: AppConstants.version,
            isManual: isManual,
            skippedVersion: preferences.skippedUpdateVersion,
            snoozedVersion: preferences.snoozedUpdateVersion,
            snoozedUntil: preferences.snoozedUpdateUntil
        )

        switch outcome {
        case .available(let info):
            preferences.lastUpdateCheckTimestamp = now
            if !isManual && sessionNotifiedVersions.contains(info.tagName) {
                return
            }
            sessionNotifiedVersions.insert(info.tagName)
            availableUpdate = info

        case .upToDate:
            preferences.lastUpdateCheckTimestamp = now
            if isManual {
                activeAlert = AlertPayload(
                    title: S.text("update_up_to_date_title", lang: lang),
                    message: String(format: S.text("update_up_to_date_msg", lang: lang), AppConstants.version)
                )
            }

        case .failed(let err):
            if isManual {
                activeAlert = AlertPayload(
                    title: S.text("update_error_title", lang: lang),
                    message: String(format: S.text("update_error_msg", lang: lang), err)
                )
            }
        }
    }

    func postponeUpdate(_ info: AvailableUpdateInfo) {
        preferences.snoozedUpdateVersion = info.tagName
        preferences.snoozedUpdateUntil = Date().timeIntervalSince1970 + 86400
        availableUpdate = nil
    }

    func skipUpdate(_ info: AvailableUpdateInfo) {
        preferences.skippedUpdateVersion = info.tagName
        availableUpdate = nil
    }

    func downloadUpdate(_ info: AvailableUpdateInfo) {
        NSWorkspace.shared.open(info.downloadURL)
        availableUpdate = nil
    }

    func clearLogs() {
        engineLogs.removeAll()
    }

    private func appendLog(_ line: String) {
        engineLogs.append(line)
        if engineLogs.count > 400 {
            engineLogs.removeFirst(engineLogs.count - 400)
        }
        Self.writeLogLineToDisk(line)
    }

    private static func writeLogLineToDisk(_ line: String) {
        let fm = FileManager.default
        guard let logsDir = fm.urls(for: .libraryDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Logs/WhisperStudio", isDirectory: true) else { return }
        try? fm.createDirectory(at: logsDir, withIntermediateDirectories: true)
        let logFile = logsDir.appendingPathComponent("engine.log")
        if let attrs = try? fm.attributesOfItem(atPath: logFile.path),
           let size = attrs[.size] as? UInt64, size > 512_000 {
            try? fm.removeItem(at: logFile)
        }
        let formatted = "[\(ISO8601DateFormatter().string(from: Date()))] \(line)\n"
        guard let data = formatted.data(using: .utf8) else { return }
        if fm.fileExists(atPath: logFile.path),
           let handle = try? FileHandle(forWritingTo: logFile) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: logFile, options: .atomic)
        }
    }

    // MARK: - File Helpers

    nonisolated private static func expandMediaURLs(_ urls: [URL]) -> [URL] {
        var result: [URL] = []
        let fm = FileManager.default
        for url in urls {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
            if isDir.boolValue {
                if let enumerator = fm.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                ) {
                    var dirFiles: [URL] = []
                    for case let child as URL in enumerator {
                        if AppConstants.validExtensions.contains(child.pathExtension.lowercased()) {
                            dirFiles.append(child)
                        }
                    }
                    result.append(contentsOf: dirFiles.sorted { $0.path < $1.path })
                }
            } else if AppConstants.validExtensions.contains(url.pathExtension.lowercased()) {
                result.append(url)
            }
        }
        return result
    }

    nonisolated private static func fileSize(at url: URL) -> Int64 {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attrs?[.size] as? NSNumber)?.int64Value ?? 0
    }

    nonisolated private static func probeDuration(for url: URL) async -> Double {
        let asset = AVURLAsset(url: url)
        if let cmDuration = try? await asset.load(.duration) {
            let secs = CMTimeGetSeconds(cmDuration)
            if secs.isFinite && secs > 0 {
                return max(1.0, secs)
            }
        }
        // Fallback to FFmpeg for containers like MKV/WEBM/OPUS
        guard let target = await MainActor.run(body: { TranscriptionProcess.resolveEngineLaunchTarget() }) else {
            return 60.0
        }
        let proc = Process()
        proc.executableURL = target.executable
        proc.arguments = target.prefixArgs + ["--probe", url.path]
        let outPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
            proc.waitUntilExit()
            let data = outPipe.fileHandleForReading.readDataToEndOfFile()
            if let obj = try? JSONDecoder().decode([String: Double].self, from: data),
               let d = obj["duration"], d > 0 {
                return d
            }
        } catch {}
        return 60.0
    }
}
