import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var state: AppState?
    private var touchBarController: TouchBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        NotificationService.shared.configure()

        if !SystemMemoryService.isSupportedEnvironment {
            let lang = state?.lang ?? .it
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = S.text("unsupported_sys_title", lang: lang)
            alert.informativeText = S.text("unsupported_sys_msg", lang: lang)
            alert.runModal()
            NSApplication.shared.terminate(nil)
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            pruneUnwantedStandardMenus()
            if let win = NSApplication.shared.windows.first, let state {
                win.titleVisibility = .hidden
                win.titlebarAppearsTransparent = true
                let tb = TouchBarController(state: state)
                self.touchBarController = tb
                state.touchBarController = tb
                tb.attach(to: win)
            }
        }
    }

    func pruneUnwantedStandardMenus() {
        guard let mainMenu = NSApp.mainMenu else { return }
        let allowedTitles: Set<String> = [
            "File",
            S.text("menu_language", lang: .it),
            S.text("menu_language", lang: .en),
            S.text("menu_settings", lang: .it),
            S.text("menu_settings", lang: .en),
            "Aiuto",
            "Help"
        ]
        // Keep index 0 (Application menu) and our explicit top-level menus only
        for idx in stride(from: mainMenu.items.count - 1, through: 1, by: -1) {
            let title = mainMenu.items[idx].title
            if !allowedTitles.contains(title) {
                mainMenu.removeItem(at: idx)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct WhisperStudioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let state = AppState()

    init() {
        // Defer delegate reference setup cleanly on appearance
    }

    private var lang: UILanguage { state.lang }

    var body: some Scene {
        Window(S.text("win_title", lang: lang), id: "main") {
            MainWindowView(state: state)
                .preferredColorScheme(.dark)
                .onAppear {
                    appDelegate.state = state
                    appDelegate.pruneUnwantedStandardMenus()
                }
                .onChange(of: state.lang) { _, _ in
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(50))
                        appDelegate.pruneUnwantedStandardMenus()
                    }
                }
        }
        .defaultSize(width: 980, height: 670)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(S.text("menu_add_files", lang: lang)) {
                    state.pickAndAddFiles()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button(S.text("menu_add_folder", lang: lang)) {
                    state.pickAndAddFolder()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Divider()

                Button(S.text("menu_clear_queue", lang: lang)) {
                    state.clearQueue()
                }
                .disabled(state.queue.isEmpty || state.isBusy)
            }

            CommandMenu(S.text("menu_language", lang: lang)) {
                Toggle("🇮🇹 Italiano", isOn: Binding(
                    get: { state.lang == .it },
                    set: { if $0 { state.setUILanguage(.it) } }
                ))
                Toggle("🇬🇧 English", isOn: Binding(
                    get: { state.lang == .en },
                    set: { if $0 { state.setUILanguage(.en) } }
                ))
            }

            CommandMenu(S.text("menu_settings", lang: lang)) {
                Toggle(
                    S.text("sett_auto_updates", lang: lang),
                    isOn: Bindable(state.preferences).autoCheckUpdates
                )

                Toggle(
                    S.text("sett_remember_engine", lang: lang),
                    isOn: Bindable(state.preferences).rememberEngineMode
                )

                Divider()

                Menu(S.text("sett_dest_header", lang: lang)) {
                    Toggle(
                        S.text("sett_dest_source", lang: lang),
                        isOn: Binding(
                            get: { state.preferences.destinationMode == .source },
                            set: { if $0 { state.preferences.destinationMode = .source } }
                        )
                    )

                    Toggle(
                        S.text("sett_dest_custom", lang: lang),
                        isOn: Binding(
                            get: { state.preferences.destinationMode == .custom },
                            set: { if $0 { state.chooseCustomDestinationFolder() } }
                        )
                    )

                    if !state.preferences.abbreviatedCustomPath.isEmpty {
                        Button("    📁 \(state.preferences.abbreviatedCustomPath)") {}
                            .disabled(true)
                    }

                    Toggle(
                        S.text("sett_dest_ask", lang: lang),
                        isOn: Binding(
                            get: { state.preferences.destinationMode == .ask },
                            set: { if $0 { state.preferences.destinationMode = .ask } }
                        )
                    )
                }
            }

            CommandGroup(replacing: .help) {
                Button(S.text("menu_guide", lang: lang)) {
                    state.showHelpSheet = true
                }

                Button(S.text("menu_logs", lang: lang)) {
                    state.showLogsSheet = true
                }

                Divider()

                Button(S.text("menu_check_updates", lang: lang)) {
                    Task {
                        await state.checkForUpdates(isManual: true)
                    }
                }
            }
        }
    }
}
