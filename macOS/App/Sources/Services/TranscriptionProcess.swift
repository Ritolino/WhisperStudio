import Foundation

final class TranscriptionProcess {
    private var process: Process?
    private var stdinHandle: FileHandle?
    private var stdoutBuffer = Data()
    private var stderrBuffer = Data()
    private var forceKillTask: Task<Void, Never>?

    var isRunning: Bool {
        process?.isRunning ?? false
    }

    static func resolveEngineLaunchTarget() -> (executable: URL, prefixArgs: [String])? {
        let bundle = Bundle.main.bundleURL
        let candidates = [
            bundle.appendingPathComponent("Contents/Resources/WhisperEngine/WhisperEngine"),
            bundle.appendingPathComponent("Contents/Helpers/WhisperEngine/WhisperEngine"),
        ]
        for bundledHelper in candidates where FileManager.default.isExecutableFile(atPath: bundledHelper.path) {
            return (bundledHelper, [])
        }

        // Development fallback when running directly via swift run outside .app bundle
        let execDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
        let devCandidates = [
            execDir.appendingPathComponent("../../../Engine/whisper_engine.py").standardizedFileURL,
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Engine/whisper_engine.py"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("macOS/Engine/whisper_engine.py"),
        ]
        let pythonPath = URL(fileURLWithPath: "/usr/bin/python3")
        for cand in devCandidates where FileManager.default.fileExists(atPath: cand.path) {
            return (pythonPath, ["-u", cand.path])
        }
        return nil
    }

    static func resolveFFmpegBinary() -> URL? {
        let bundle = Bundle.main.bundleURL
        let candidates = [
            bundle.appendingPathComponent("Contents/Resources/WhisperEngine/ffmpeg"),
            bundle.appendingPathComponent("Contents/Resources/WhisperEngine/_internal/ffmpeg"),
            bundle.appendingPathComponent("Contents/Helpers/WhisperEngine/ffmpeg"),
            bundle.appendingPathComponent("Contents/Helpers/WhisperEngine/_internal/ffmpeg"),
            bundle.appendingPathComponent("Contents/Resources/ffmpeg"),
            URL(fileURLWithPath: "/opt/homebrew/bin/ffmpeg"),
            URL(fileURLWithPath: "/usr/local/bin/ffmpeg"),
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    func start(
        command: StartBatchCommand,
        onEvent: @escaping @MainActor (RawEngineEvent) -> Void,
        onLog: @escaping @MainActor (String) -> Void,
        onTerminate: @escaping @MainActor (Int32) -> Void
    ) throws {
        guard let target = Self.resolveEngineLaunchTarget() else {
            throw NSError(
                domain: "WhisperStudio",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "WhisperEngine binary not found inside application bundle."]
            )
        }

        let proc = Process()
        proc.executableURL = target.executable
        proc.arguments = target.prefixArgs

        var env = ProcessInfo.processInfo.environment
        env["PYTHONUNBUFFERED"] = "1"
        if let ff = Self.resolveFFmpegBinary() {
            let ffDir = ff.deletingLastPathComponent().path
            env["PATH"] = "\(ffDir):\(env["PATH"] ?? "/usr/bin:/bin")"
        }
        proc.environment = env

        let inPipe = Pipe()
        let outPipe = Pipe()
        let errPipe = Pipe()

        proc.standardInput = inPipe
        proc.standardOutput = outPipe
        proc.standardError = errPipe

        stdoutBuffer.removeAll()
        stderrBuffer.removeAll()

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            if chunk.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            Task { @MainActor [weak self] in
                self?.consumeStdoutChunk(chunk, onEvent: onEvent, onLog: onLog)
            }
        }

        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            if chunk.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            Task { @MainActor [weak self] in
                self?.consumeStderrChunk(chunk, onLog: onLog)
            }
        }

        proc.terminationHandler = { [weak self] finishedProc in
            outPipe.fileHandleForReading.readabilityHandler = nil
            errPipe.fileHandleForReading.readabilityHandler = nil
            let status = finishedProc.terminationStatus
            Task { @MainActor [weak self] in
                self?.forceKillTask?.cancel()
                self?.forceKillTask = nil
                self?.stdinHandle = nil
                self?.process = nil
                onTerminate(status)
            }
        }

        try proc.run()
        self.process = proc
        self.stdinHandle = inPipe.fileHandleForWriting

        sendJSONCommand(command)
    }

    func sendPause() {
        sendJSONCommand(SimpleCommand(cmd: "pause"))
    }

    func sendResume() {
        sendJSONCommand(SimpleCommand(cmd: "resume"))
    }

    func sendAppendFiles(_ files: [EngineFilePayload]) {
        guard !files.isEmpty else { return }
        sendJSONCommand(AppendFilesCommand(files: files))
    }

    func sendRemoveFile(id: UUID) {
        sendJSONCommand(RemoveFileCommand(id: id.uuidString))
    }

    func sendReorderFiles(orderedIDs: [UUID]) {
        sendJSONCommand(ReorderFilesCommand(ordered_ids: orderedIDs.map(\.uuidString)))
    }

    func cancelWithTimeout(ms: UInt64 = 800) {
        sendJSONCommand(SimpleCommand(cmd: "cancel"))
        try? stdinHandle?.close()
        stdinHandle = nil

        guard let proc = process, proc.isRunning else { return }
        forceKillTask?.cancel()
        forceKillTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(ms))
            guard !Task.isCancelled else { return }
            if let activeProc = self?.process, activeProc.isRunning {
                activeProc.terminate()
            }
        }
    }

    private func sendJSONCommand<T: Encodable>(_ value: T) {
        guard let handle = stdinHandle else { return }
        guard var data = try? JSONEncoder().encode(value) else { return }
        data.append(0x0A) // '\n'
        do {
            try handle.write(contentsOf: data)
        } catch {
            // Helper may have already closed stdin on termination
        }
    }

    private func consumeStdoutChunk(
        _ chunk: Data,
        onEvent: @MainActor (RawEngineEvent) -> Void,
        onLog: @MainActor (String) -> Void
    ) {
        stdoutBuffer.append(chunk)
        let newline = Data([0x0A])
        while let range = stdoutBuffer.range(of: newline) {
            let lineData = stdoutBuffer.subdata(in: 0..<range.lowerBound)
            stdoutBuffer.removeSubrange(0..<range.upperBound)
            guard !lineData.isEmpty else { continue }
            if let event = try? JSONDecoder().decode(RawEngineEvent.self, from: lineData) {
                onEvent(event)
            } else if let str = String(data: lineData, encoding: .utf8) {
                onLog("[stdout non-json] \(str)")
            }
        }
    }

    private func consumeStderrChunk(_ chunk: Data, onLog: @MainActor (String) -> Void) {
        stderrBuffer.append(chunk)
        let newline = Data([0x0A])
        while let range = stderrBuffer.range(of: newline) {
            let lineData = stderrBuffer.subdata(in: 0..<range.lowerBound)
            stderrBuffer.removeSubrange(0..<range.upperBound)
            if let line = String(data: lineData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !line.isEmpty {
                onLog(line)
            }
        }
    }
}
