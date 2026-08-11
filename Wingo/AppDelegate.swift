import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var switcherWindowController: SwitcherWindowController?
    private var globalShortcutService: GlobalShortcutService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let windowController = SwitcherWindowController()
        switcherWindowController = windowController

        let shortcutService = GlobalShortcutService { [weak windowController] in
            windowController?.show()
        }
        globalShortcutService = shortcutService

        windowController.show()

        do {
            try shortcutService.start()
        } catch {
            showShortcutRegistrationError(error, on: windowController.window)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        globalShortcutService?.stop()
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
