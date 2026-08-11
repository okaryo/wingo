import AppKit
import ApplicationServices

struct WindowIdentifier: Hashable {
    let processIdentifier: pid_t
    let accessibilityElementHash: CFHashCode
}

final class AccessibilityWindowReference {
    let element: AXUIElement

    init(element: AXUIElement) {
        self.element = element
    }
}

struct WindowItem: Identifiable {
    let id: WindowIdentifier
    let processIdentifier: pid_t
    let applicationName: String
    let applicationIcon: NSImage?
    let windowTitle: String

    // Window操作はService層だけがこの参照を利用する。
    let accessibilityReference: AccessibilityWindowReference
}
