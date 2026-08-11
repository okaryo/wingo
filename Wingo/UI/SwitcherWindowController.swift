import AppKit
import SwiftUI

extension Notification.Name {
    static let wingoSwitcherWillShow = Notification.Name("wingoSwitcherWillShow")
}

@MainActor
final class SwitcherWindowController {
    let window: SwitcherPanel

    init() {
        let window = SwitcherPanel(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        let hostingController = NSHostingController(
            rootView: WindowListView(
                onDismiss: { [weak window] in
                    window?.orderOut(nil)
                },
                onActivationFailure: { [weak window] in
                    guard let window else {
                        return
                    }
                    NSApp.activate()
                    window.makeKeyAndOrderFront(nil)
                }
            )
                .frame(minWidth: 560, minHeight: 420)
        )
        window.contentViewController = hostingController
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        window.animationBehavior = .utilityWindow
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.hidesOnDeactivate = true
        window.isReleasedWhenClosed = false
        self.window = window
    }

    func show() {
        positionOnActiveScreen()
        NotificationCenter.default.post(name: .wingoSwitcherWillShow, object: nil)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func hide() {
        window.orderOut(nil)
    }

    private func positionOnActiveScreen() {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else {
            return
        }

        let windowSize = window.frame.size
        let origin = NSPoint(
            x: visibleFrame.midX - windowSize.width / 2,
            y: visibleFrame.midY - windowSize.height / 2
        )
        window.setFrameOrigin(origin)
    }
}

final class SwitcherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
