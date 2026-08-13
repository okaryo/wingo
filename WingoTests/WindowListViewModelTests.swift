import AppKit
import ApplicationServices
import XCTest

@MainActor
final class WindowListViewModelTests: XCTestCase {
    func testBuildsApplicationTabsFromWindowOrderWithCounts() {
        let appAFirst = makeWindow(id: 1, application: 10, name: "App A")
        let appASecond = makeWindow(id: 2, application: 10, name: "App A")
        let appB = makeWindow(id: 3, application: 20, name: "App B")
        let history = WindowHistory()
        history.recordFocusedWindow(appAFirst.id)
        history.recordFocusedWindow(appB.id)
        let viewModel = makeViewModel(
            windows: [appAFirst, appASecond, appB],
            history: history
        )

        viewModel.load(resetSelection: true)

        XCTAssertEqual(viewModel.applicationTabs.map(\.applicationName), ["App A", "App B"])
        XCTAssertEqual(viewModel.applicationTabs.map(\.windowCount), [2, 1])
        XCTAssertEqual(viewModel.allWindowCount, 3)
    }

    func testInitialSelectionAndShortcutsFollowOrderingWithCurrentWindowLast() {
        let older = makeWindow(id: 1, application: 10, name: "App A")
        let previous = makeWindow(id: 2, application: 20, name: "App B")
        let current = makeWindow(id: 3, application: 30, name: "App C")
        let history = WindowHistory()
        history.recordFocusedWindow(older.id)
        history.recordFocusedWindow(previous.id)
        history.recordFocusedWindow(current.id)
        let viewModel = makeViewModel(
            windows: [older, previous, current],
            history: history
        )

        viewModel.load(resetSelection: true)

        XCTAssertEqual(viewModel.windows.map(\.id), [previous.id, older.id, current.id])
        XCTAssertEqual(viewModel.selectedWindowID, previous.id)
        XCTAssertTrue(viewModel.selectWindow(forShortcutNumber: 1))
        XCTAssertEqual(viewModel.selectedWindowID, previous.id)
    }

    func testSelectingApplicationFiltersWindowsWithoutChangingTheirMRUOrder() {
        let older = makeWindow(id: 1, application: 10, name: "App A")
        let newer = makeWindow(id: 2, application: 10, name: "App A")
        let other = makeWindow(id: 3, application: 20, name: "App B")
        let history = WindowHistory()
        history.recordFocusedWindow(older.id)
        history.recordFocusedWindow(newer.id)
        history.recordFocusedWindow(other.id)
        let viewModel = makeViewModel(windows: [older, newer, other], history: history)
        viewModel.load(resetSelection: true)

        viewModel.selectApplication(.application(older.applicationIdentifier))

        XCTAssertEqual(viewModel.windows.map(\.id), [newer.id, older.id])
    }

    func testSelectingApplicationResetsWindowSelectionToFirstVisibleWindow() {
        let appAFirst = makeWindow(id: 1, application: 10, name: "App A")
        let appB = makeWindow(id: 2, application: 20, name: "App B")
        let appASecond = makeWindow(id: 3, application: 10, name: "App A")
        let viewModel = makeViewModel(windows: [appAFirst, appB, appASecond])
        viewModel.load(resetSelection: true)
        viewModel.selectedWindowID = appASecond.id

        viewModel.selectApplication(.application(appAFirst.applicationIdentifier))

        XCTAssertEqual(viewModel.windows.map(\.id), [appAFirst.id, appASecond.id])
        XCTAssertEqual(viewModel.selectedWindowID, appAFirst.id)
    }

    func testApplicationSelectionWrapsAcrossAllAndApplicationTabs() {
        let appA = makeWindow(id: 1, application: 10, name: "App A")
        let appB = makeWindow(id: 2, application: 20, name: "App B")
        let viewModel = makeViewModel(windows: [appA, appB])
        viewModel.load(resetSelection: true)

        viewModel.moveApplicationSelection(.previous)
        XCTAssertEqual(viewModel.selectedApplication, .application(appB.applicationIdentifier))

        viewModel.moveApplicationSelection(.next)
        XCTAssertEqual(viewModel.selectedApplication, .all)

        viewModel.moveApplicationSelection(.next)
        XCTAssertEqual(viewModel.selectedApplication, .application(appA.applicationIdentifier))
    }

    func testDirectShortcutUsesFilteredWindowIndexes() {
        let appAFirst = makeWindow(id: 1, application: 10, name: "App A")
        let appB = makeWindow(id: 2, application: 20, name: "App B")
        let appASecond = makeWindow(id: 3, application: 10, name: "App A")
        let viewModel = makeViewModel(windows: [appAFirst, appB, appASecond])
        viewModel.load(resetSelection: true)
        viewModel.selectApplication(.application(appAFirst.applicationIdentifier))

        XCTAssertTrue(viewModel.selectWindow(forShortcutNumber: 2))
        XCTAssertEqual(viewModel.selectedWindowID, appASecond.id)
        XCTAssertFalse(viewModel.selectWindow(forShortcutNumber: 3))
    }

    func testResetSelectionReturnsToAll() {
        let appA = makeWindow(id: 1, application: 10, name: "App A")
        let appB = makeWindow(id: 2, application: 20, name: "App B")
        let viewModel = makeViewModel(windows: [appA, appB])
        viewModel.load(resetSelection: true)
        viewModel.selectApplication(.application(appB.applicationIdentifier))

        viewModel.load(resetSelection: true)

        XCTAssertEqual(viewModel.selectedApplication, .all)
        XCTAssertEqual(viewModel.windows.map(\.id), [appA.id, appB.id])
    }

    func testResetSelectionReturnsWindowSelectionToFirstWindow() {
        let first = makeWindow(id: 1, application: 10, name: "App A")
        let last = makeWindow(id: 2, application: 20, name: "App B")
        let viewModel = makeViewModel(windows: [first, last])
        viewModel.load(resetSelection: true)
        viewModel.selectedWindowID = last.id

        viewModel.load(resetSelection: true)

        XCTAssertEqual(viewModel.selectedWindowID, first.id)
    }

    private func makeViewModel(
        windows: [WindowItem],
        history: WindowHistory = WindowHistory()
    ) -> WindowListViewModel {
        WindowListViewModel(
            windowHistory: history,
            discoverWindows: {
                WindowDiscoveryResult(
                    windows: windows,
                    inspectedApplicationCount: 0,
                    inaccessibleApplicationCount: 0
                )
            },
            isAccessibilityTrusted: { _ in true }
        )
    }

    private func makeWindow(
        id: Int32,
        application: Int32,
        name: String
    ) -> WindowItem {
        let processIdentifier = pid_t(application)
        return WindowItem(
            id: WindowIdentifier(
                processIdentifier: processIdentifier,
                accessibilityElementHash: CFHashCode(id)
            ),
            applicationIdentifier: ApplicationIdentifier(
                bundleIdentifier: "studio.okaryo.application-\(application)",
                processIdentifier: processIdentifier
            ),
            processIdentifier: processIdentifier,
            applicationName: name,
            applicationIcon: nil,
            windowTitle: "Window \(id)",
            accessibilityReference: AccessibilityWindowReference(
                element: AXUIElementCreateApplication(processIdentifier)
            )
        )
    }
}
