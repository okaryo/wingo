import AppKit
@preconcurrency import ApplicationServices

enum WindowActivationError: LocalizedError {
    case applicationNotRunning(String)
    case invalidWindowReference
    case applicationActivationRejected(String)
    case raiseFailed(AXError)
    case focusFailed

    var errorDescription: String? {
        switch self {
        case let .applicationNotRunning(applicationName):
            return "\(applicationName) is no longer running. Refresh the window list and try again."
        case .invalidWindowReference:
            return "The selected window is no longer available. Refresh the window list and try again."
        case let .applicationActivationRejected(applicationName):
            return "macOS did not allow Wingo to activate \(applicationName)."
        case let .raiseFailed(error):
            return "The selected window could not be raised (Accessibility error \(error.rawValue))."
        case .focusFailed:
            return "The application was activated, but the selected window could not be focused."
        }
    }
}

@MainActor
enum WindowActivationService {
    static func activate(_ window: WindowItem) -> Result<Void, WindowActivationError> {
        guard
            let application = NSRunningApplication(processIdentifier: window.processIdentifier),
            !application.isTerminated
        else {
            return .failure(.applicationNotRunning(window.applicationName))
        }

        let windowElement = window.accessibilityReference.element
        var elementProcessIdentifier: pid_t = 0
        guard
            AXUIElementGetPid(windowElement, &elementProcessIdentifier) == .success,
            elementProcessIdentifier == window.processIdentifier
        else {
            return .failure(.invalidWindowReference)
        }

        guard application.activate(options: []) else {
            return .failure(.applicationActivationRejected(window.applicationName))
        }

        // Restoring is best-effort because not every window exposes a writable minimized attribute.
        AXUIElementSetAttributeValue(
            windowElement,
            kAXMinimizedAttribute as CFString,
            kCFBooleanFalse
        )

        let raiseError = AXUIElementPerformAction(windowElement, kAXRaiseAction as CFString)
        guard raiseError == .success else {
            return .failure(.raiseFailed(raiseError))
        }

        let applicationElement = AXUIElementCreateApplication(window.processIdentifier)
        let focusedWindowError = AXUIElementSetAttributeValue(
            applicationElement,
            kAXFocusedWindowAttribute as CFString,
            windowElement
        )
        let mainWindowError = AXUIElementSetAttributeValue(
            windowElement,
            kAXMainAttribute as CFString,
            kCFBooleanTrue
        )
        let focusedError = AXUIElementSetAttributeValue(
            windowElement,
            kAXFocusedAttribute as CFString,
            kCFBooleanTrue
        )

        guard [focusedWindowError, mainWindowError, focusedError].contains(.success) else {
            return .failure(.focusFailed)
        }

        return .success(())
    }
}
