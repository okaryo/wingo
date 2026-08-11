import AppKit
import ApplicationServices

struct WindowIdentifier: Hashable {
    let processIdentifier: pid_t
    let accessibilityElementHash: CFHashCode

    init(processIdentifier: pid_t, accessibilityElement: AXUIElement) {
        self.processIdentifier = processIdentifier
        accessibilityElementHash = CFHash(accessibilityElement)
    }

    init(processIdentifier: pid_t, accessibilityElementHash: CFHashCode) {
        self.processIdentifier = processIdentifier
        self.accessibilityElementHash = accessibilityElementHash
    }
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
