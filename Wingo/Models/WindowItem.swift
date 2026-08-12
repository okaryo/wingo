import AppKit
import ApplicationServices

struct ApplicationIdentifier: Hashable {
    private let rawValue: String

    init(bundleIdentifier: String?, processIdentifier: pid_t) {
        if let bundleIdentifier,
           !bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            rawValue = "bundle:\(bundleIdentifier)"
        } else {
            rawValue = "process:\(processIdentifier)"
        }
    }
}

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
    let applicationIdentifier: ApplicationIdentifier
    let processIdentifier: pid_t
    let applicationName: String
    let applicationIcon: NSImage?
    let windowTitle: String

    // Window操作はService層だけがこの参照を利用する。
    let accessibilityReference: AccessibilityWindowReference
}
