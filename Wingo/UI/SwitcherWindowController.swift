import AppKit
import SwiftUI

extension Notification.Name {
    static let wingoSwitcherWillShow = Notification.Name("wingoSwitcherWillShow")
}

@MainActor
final class SwitcherWindowController {
    let window: NSWindow

    init() {
        let hostingController = NSHostingController(
            rootView: WindowListView()
                .frame(minWidth: 560, minHeight: 420)
        )
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Wingo — Phase 3"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 680, height: 560))
        window.minSize = NSSize(width: 560, height: 420)
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
    }

    func show() {
        NotificationCenter.default.post(name: .wingoSwitcherWillShow, object: nil)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}
