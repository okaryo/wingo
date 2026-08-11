import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var switcherWindowController: SwitcherWindowController?
    private var globalShortcutService: GlobalShortcutService?
    private var windowFocusObserverService: WindowFocusObserverService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let windowHistory = WindowHistory()
        let focusObserverService = WindowFocusObserverService(history: windowHistory)
        windowFocusObserverService = focusObserverService
        focusObserverService.startOrRefresh()

        let windowController = SwitcherWindowController(
            windowHistory: windowHistory,
            beforeShow: { [weak focusObserverService] in
                focusObserverService?.startOrRefresh()
            }
        )
        switcherWindowController = windowController

        let shortcutService = GlobalShortcutService { [weak windowController] in
            windowController?.show()
        }
        globalShortcutService = shortcutService

        do {
            try shortcutService.start()
        } catch {
            windowController.show()
            showShortcutRegistrationError(error, on: windowController.window)
            return
        }

        if !AccessibilityService.isTrusted(promptIfNeeded: false) {
            windowController.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        globalShortcutService?.stop()
        windowFocusObserverService?.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        switcherWindowController?.show()
        return true
    }

    private func showShortcutRegistrationError(_ error: Error, on window: NSWindow) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Global Shortcut Unavailable"
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: window)
    }
}
