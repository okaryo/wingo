import AppKit
import ApplicationServices
import XCTest

@MainActor
final class WindowHistoryTests: XCTestCase {
    func testOrdersKnownWindowsByMostRecentFocus() {
        let first = makeWindow(1)
        let second = makeWindow(2)
        let third = makeWindow(3)
        let history = WindowHistory()

        history.recordFocusedWindow(second.id)
        history.recordFocusedWindow(third.id)

        XCTAssertEqual(
            history.orderedWindows([first, second, third]).map(\.id),
            [third.id, second.id, first.id]
        )
    }

    func testPreservesDiscoveryOrderForUntrackedWindows() {
        let windows = [makeWindow(1), makeWindow(2), makeWindow(3)]
        let history = WindowHistory()

        XCTAssertEqual(history.orderedWindows(windows).map(\.id), windows.map(\.id))
    }

    func testInitiallySelectsPreviousWindowInsteadOfCurrentWindow() {
        let previous = makeWindow(1)
        let current = makeWindow(2)
        let other = makeWindow(3)
        let history = WindowHistory()

        history.recordFocusedWindow(previous.id)
        history.recordFocusedWindow(current.id)
        let orderedWindows = history.orderedWindows([previous, current, other])

        XCTAssertEqual(orderedWindows.first?.id, current.id)
        XCTAssertEqual(history.initialSelection(in: orderedWindows), previous.id)
    }

    func testSelectsCurrentWindowWhenItIsTheOnlyWindow() {
        let current = makeWindow(1)
        let history = WindowHistory()
        history.recordFocusedWindow(current.id)

        XCTAssertEqual(history.initialSelection(in: [current]), current.id)
    }

    private func makeWindow(_ value: Int32) -> WindowItem {
        let processIdentifier = pid_t(value)
        return WindowItem(
            id: WindowIdentifier(
                processIdentifier: processIdentifier,
                accessibilityElementHash: CFHashCode(value)
            ),
            processIdentifier: processIdentifier,
            applicationName: "Application \(value)",
            applicationIcon: nil,
            windowTitle: "Window \(value)",
            accessibilityReference: AccessibilityWindowReference(
                element: AXUIElementCreateApplication(processIdentifier)
            )
        )
    }
}
