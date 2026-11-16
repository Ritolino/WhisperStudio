import Foundation

nonisolated enum AppConstants {
    static let version = "3.0.5"
    static let githubRepo = "Ritolino/WhisperStudio"
    static let validExtensions: Set<String> = [
        "mp3", "m4a", "wav", "mp4", "mov", "mkv",
        "aac", "ogg", "webm", "flac", "alac", "opus", "wma", "aiff"
    ]
}

enum UILanguage: String, CaseIterable, Sendable, Codable {
    case it
    case en
}

enum AudioLanguageMode: String, CaseIterable, Sendable, Codable {
    case primary
    case auto

    func engineCode(for uiLanguage: UILanguage) -> String {
        switch self {
        case .primary:
            return uiLanguage == .it ? "it" : "en"
        case .auto:
            return "auto"
        }
    }
}

enum TranscriptionModelOption: String, CaseIterable, Sendable, Codable {
    case standard
    case turbo

    var huggingFaceRepo: String {
        switch self {
        case .standard: return "mlx-community/whisper-large-v3-mlx"
        case .turbo: return "mlx-community/whisper-large-v3-turbo"
        }
    }
}

enum DestinationMode: String, CaseIterable, Sendable, Codable {
    case source
    case custom
    case ask
}

enum QueueItemStatus: Equatable, Sendable {
    case waiting
    case downloadingModel
    case loadingModel
    case running
    case completed
    case error
    case cancelled
}

struct QueueItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let url: URL
    var fileName: String { url.lastPathComponent }
    var fileSizeBytes: Int64
    var durationSeconds: Double
    var status: QueueItemStatus = .waiting
    var progressPercent: Int = 0
    var elapsedSeconds: Double = 0
    var remainingSeconds: Double = 0
    var errorMessage: String?
    var outputPaths: [URL] = []
}

enum EngineRunState: Equatable, Sendable {
    case idle
    case starting
    case downloadingModel(percent: Int, message: String)
    case transcribing
    case paused
    case stopping
}

// MARK: - JSON Lines Commands (GUI -> WhisperEngine)

struct EngineFilePayload: Encodable, Sendable {
    let id: String
    let path: String
    let duration: Double
}

struct StartBatchCommand: Encodable, Sendable {
    var cmd: String = "start_batch"
    let model_repo: String
    let language: String
    let formats: [String]
    let ui_lang: String
    let dest_dir: String?
    let files: [EngineFilePayload]
}

struct SimpleCommand: Encodable, Sendable {
    let cmd: String
}

struct AppendFilesCommand: Encodable, Sendable {
    var cmd: String = "append_files"
    let files: [EngineFilePayload]
}

struct RemoveFileCommand: Encodable, Sendable {
    var cmd: String = "remove_file"
    let id: String
}

struct ReorderFilesCommand: Encodable, Sendable {
    var cmd: String = "reorder_files"
    let ordered_ids: [String]
}

// MARK: - JSON Lines Events (WhisperEngine -> GUI)

struct RawEngineEvent: Decodable, Sendable {
    let event: String
    let cached: Bool?
    let repo: String?
    let percent: Int?
    let message: String?
    let resolved_path: String?
    let id: String?
    let path: String?
    let index: Int?
    let total: Int?
    let file_percent: Int?
    let file_elapsed: Double?
    let file_remaining: Double?
    let total_percent: Int?
    let total_elapsed: Double?
    let total_remaining: Double?
    let outputs: [String]?
    let error: String?
    let completed_count: Int?
    let last_output_dir: String?
}
