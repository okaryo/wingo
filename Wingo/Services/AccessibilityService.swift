import AppKit
@preconcurrency import ApplicationServices

enum AccessibilityService {
    static func isTrusted(promptIfNeeded: Bool) -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: promptIfNeeded
        ] as CFDictionary

        return AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
