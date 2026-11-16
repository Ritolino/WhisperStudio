import Foundation
import Observation

@Observable
final class AppPreferences {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let uiLanguage = "uiLanguage"
        static let rememberEngineMode = "rememberEngineMode"
        static let isManualModelMode = "isManualModelMode"
        static let selectedManualModel = "selectedManualModel"
        static let audioLanguage = "audioLanguage"
        static let exportTxt = "exportTxt"
        static let exportDocx = "exportDocx"
        static let autoCheckUpdates = "autoCheckUpdates"
        static let lastUpdateCheckTimestamp = "lastUpdateCheckTimestamp"
        static let skippedUpdateVersion = "skippedUpdateVersion"
        static let snoozedUpdateVersion = "snoozedUpdateVersion"
        static let snoozedUpdateUntil = "snoozedUpdateUntil"
        static let destinationMode = "destinationMode"
        static let customDestinationPath = "customDestinationPath"
    }

    var uiLanguage: UILanguage {
        didSet { defaults.set(uiLanguage.rawValue, forKey: Keys.uiLanguage) }
    }

    var rememberEngineMode: Bool {
        didSet { defaults.set(rememberEngineMode, forKey: Keys.rememberEngineMode) }
    }

    var isManualModelMode: Bool {
        didSet { defaults.set(isManualModelMode, forKey: Keys.isManualModelMode) }
    }

    var selectedManualModel: TranscriptionModelOption {
        didSet { defaults.set(selectedManualModel.rawValue, forKey: Keys.selectedManualModel) }
    }

    var audioLanguage: AudioLanguageMode {
        didSet { defaults.set(audioLanguage.rawValue, forKey: Keys.audioLanguage) }
    }

    var exportTxt: Bool {
        didSet { defaults.set(exportTxt, forKey: Keys.exportTxt) }
    }

    var exportDocx: Bool {
        didSet { defaults.set(exportDocx, forKey: Keys.exportDocx) }
    }

    var autoCheckUpdates: Bool {
        didSet { defaults.set(autoCheckUpdates, forKey: Keys.autoCheckUpdates) }
    }

    var lastUpdateCheckTimestamp: Double {
        didSet { defaults.set(lastUpdateCheckTimestamp, forKey: Keys.lastUpdateCheckTimestamp) }
    }

    var skippedUpdateVersion: String {
        didSet { defaults.set(skippedUpdateVersion, forKey: Keys.skippedUpdateVersion) }
    }

    var snoozedUpdateVersion: String {
        didSet { defaults.set(snoozedUpdateVersion, forKey: Keys.snoozedUpdateVersion) }
    }

    var snoozedUpdateUntil: Double {
        didSet { defaults.set(snoozedUpdateUntil, forKey: Keys.snoozedUpdateUntil) }
    }

    var destinationMode: DestinationMode {
        didSet { defaults.set(destinationMode.rawValue, forKey: Keys.destinationMode) }
    }

    var customDestinationPath: String {
        didSet { defaults.set(customDestinationPath, forKey: Keys.customDestinationPath) }
    }

    init() {
        let detected = Self.detectSystemLanguage()
        if let rawLang = defaults.string(forKey: Keys.uiLanguage),
           let parsedLang = UILanguage(rawValue: rawLang) {
            self.uiLanguage = parsedLang
        } else {
            self.uiLanguage = detected
        }

        let remember = defaults.object(forKey: Keys.rememberEngineMode) as? Bool ?? true
        self.rememberEngineMode = remember

        if remember {
            self.isManualModelMode = defaults.bool(forKey: Keys.isManualModelMode)
        } else {
            self.isManualModelMode = false
        }

        if let rawModel = defaults.string(forKey: Keys.selectedManualModel),
           let parsedModel = TranscriptionModelOption(rawValue: rawModel) {
            self.selectedManualModel = parsedModel
        } else {
            self.selectedManualModel = .standard
        }

        if let rawAudio = defaults.string(forKey: Keys.audioLanguage),
           let parsedAudio = AudioLanguageMode(rawValue: rawAudio) {
            self.audioLanguage = parsedAudio
        } else {
            self.audioLanguage = .primary
        }

        let initTxt = defaults.object(forKey: Keys.exportTxt) as? Bool ?? false
        var initDocx = defaults.object(forKey: Keys.exportDocx) as? Bool ?? true
        if !initTxt && !initDocx {
            initDocx = true
        }
        self.exportTxt = initTxt
        self.exportDocx = initDocx

        self.autoCheckUpdates = defaults.object(forKey: Keys.autoCheckUpdates) as? Bool ?? true
        self.lastUpdateCheckTimestamp = defaults.double(forKey: Keys.lastUpdateCheckTimestamp)
        self.skippedUpdateVersion = defaults.string(forKey: Keys.skippedUpdateVersion) ?? ""
        self.snoozedUpdateVersion = defaults.string(forKey: Keys.snoozedUpdateVersion) ?? ""
        self.snoozedUpdateUntil = defaults.double(forKey: Keys.snoozedUpdateUntil)

        let customPathVal = defaults.string(forKey: Keys.customDestinationPath) ?? ""
        self.customDestinationPath = customPathVal

        if let rawDest = defaults.string(forKey: Keys.destinationMode),
           let parsedDest = DestinationMode(rawValue: rawDest),
           !(parsedDest == .custom && customPathVal.isEmpty) {
            self.destinationMode = parsedDest
        } else {
            self.destinationMode = .source
        }
    }

    func setExportDocx(_ enabled: Bool) {
        if !enabled && !exportTxt {
            exportTxt = true
        }
        exportDocx = enabled
    }

    func setExportTxt(_ enabled: Bool) {
        if !enabled && !exportDocx {
            exportDocx = true
        }
        exportTxt = enabled
    }

    var abbreviatedCustomPath: String {
        guard !customDestinationPath.isEmpty else { return "" }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var display = customDestinationPath
        if display.hasPrefix(home) {
            display = "~" + display.dropFirst(home.count)
        }
        if display.count > 44 {
            return "…" + String(display.suffix(42))
        }
        return display
    }

    private static func detectSystemLanguage() -> UILanguage {
        for lang in Locale.preferredLanguages {
            let lower = lang.lowercased()
            if lower.hasPrefix("it") { return .it }
            if lower.hasPrefix("en") { return .en }
        }
        return .en
    }
}
