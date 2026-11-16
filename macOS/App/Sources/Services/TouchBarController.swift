import AppKit

private extension NSTouchBarItem.Identifier {
    static let start = NSTouchBarItem.Identifier("com.whisperstudio.tb.start")
    static let pause = NSTouchBarItem.Identifier("com.whisperstudio.tb.pause")
    static let cancel = NSTouchBarItem.Identifier("com.whisperstudio.tb.cancel")
    static let status = NSTouchBarItem.Identifier("com.whisperstudio.tb.status")
}

final class TouchBarController: NSObject, NSTouchBarDelegate {
    private weak var state: AppState?
    private lazy var touchBar: NSTouchBar = {
        let tb = NSTouchBar()
        tb.delegate = self
        tb.defaultItemIdentifiers = [.start, .pause, .cancel, .flexibleSpace, .status]
        return tb
    }()

    private var btnStart: NSButton?
    private var btnPause: NSButton?
    private var btnCancel: NSButton?
    private var lblStatus: NSTextField?

    init(state: AppState) {
        self.state = state
        super.init()
    }

    func attach(to window: NSWindow) {
        window.touchBar = touchBar
        refresh()
    }

    func refresh() {
        guard let state else { return }
        let lang = state.preferences.uiLanguage
        let isRunning = state.runState != .idle
        let isDownloading: Bool = if case .downloadingModel = state.runState { true } else { false }
        let isPaused = state.runState == .paused

        btnStart?.title = S.text("btn_start", lang: lang)
        btnStart?.isEnabled = !isRunning && !state.queue.isEmpty

        btnPause?.isHidden = isDownloading
        btnPause?.isEnabled = isRunning && !isDownloading && state.runState != .stopping
        btnPause?.title = S.text(isPaused ? "btn_resume" : "btn_pause", lang: lang)

        btnCancel?.isEnabled = isRunning && state.runState != .stopping
        btnCancel?.title = S.text(isDownloading ? "btn_cancel_download" : "btn_cancel", lang: lang)

        let statusText: String
        switch state.runState {
        case .idle:
            statusText = state.queue.isEmpty
                ? S.text("tb_ready", lang: lang)
                : "\(state.queue.count) file"
        case .starting:
            statusText = S.text("tb_loading", lang: lang)
        case .downloadingModel(let p, _):
            statusText = "\(p)%"
        case .transcribing:
            statusText = "\(state.totalProgressPercent)%"
        case .paused:
            statusText = S.text("tb_paused", lang: lang)
        case .stopping:
            statusText = S.text("tb_cancelled", lang: lang)
        }
        lblStatus?.stringValue = statusText
    }

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        let item = NSCustomTouchBarItem(identifier: identifier)
        switch identifier {
        case .start:
            let btn = NSButton(title: "Start", target: self, action: #selector(onStart))
            btn.bezelColor = .systemIndigo
            btnStart = btn
            item.view = btn
        case .pause:
            let btn = NSButton(title: "Pause", target: self, action: #selector(onPause))
            btnPause = btn
            item.view = btn
        case .cancel:
            let btn = NSButton(title: "Cancel", target: self, action: #selector(onCancel))
            btn.bezelColor = .systemRed
            btnCancel = btn
            item.view = btn
        case .status:
            let lbl = NSTextField(labelWithString: "Ready")
            lbl.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
            lbl.textColor = .secondaryLabelColor
            lblStatus = lbl
            item.view = lbl
        default:
            return nil
        }
        refresh()
        return item
    }

    @objc private func onStart() {
        state?.startTranscription()
    }

    @objc private func onPause() {
        state?.togglePause()
    }

    @objc private func onCancel() {
        state?.cancelTranscription()
    }
}
