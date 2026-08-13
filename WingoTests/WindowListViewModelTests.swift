import AppKit
import ApplicationServices
import XCTest

@MainActor
final class WindowListViewModelTests: XCTestCase {
    func testBuildsApplicationTabsOnlyForApplicationsWithMultipleWindows() {
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

        XCTAssertEqual(viewModel.applicationTabs.map(\.applicationName), ["App A"])
        XCTAssertEqual(viewModel.applicationTabs.map(\.windowCount), [2])
        XCTAssertEqual(viewModel.allWindowCount, 3)
        XCTAssertEqual(viewModel.otherApplicationWindowCount, 1)
        XCTAssertTrue(viewModel.hasOtherApplicationsTab)
    }

    func testBuildsNoApplicationTabsWhenEveryApplicationHasOneWindow() {
        let appA = makeWindow(id: 1, application: 10, name: "App A")
        let appB = makeWindow(id: 2, application: 20, name: "App B")
        let viewModel = makeViewModel(windows: [appA, appB])

        viewModel.load(resetSelection: true)

        XCTAssertTrue(viewModel.applicationTabs.isEmpty)
        XCTAssertFalse(viewModel.hasOtherApplicationsTab)
        XCTAssertEqual(viewModel.selectedApplication, .all)
        XCTAssertEqual(viewModel.windows.map(\.id), [appA.id, appB.id])
    }

    func testApplicationNavigationStaysOnAllWhenThereAreNoApplicationTabs() {
        let appA = makeWindow(id: 1, application: 10, name: "App A")
        let appB = makeWindow(id: 2, application: 20, name: "App B")
        let viewModel = makeViewModel(windows: [appA, appB])
        viewModel.load(resetSelection: true)

        viewModel.moveApplicationSelection(.next)
        viewModel.moveApplicationSelection(.previous)

        XCTAssertEqual(viewModel.selectedApplication, .all)
        XCTAssertEqual(viewModel.windows.map(\.id), [appA.id, appB.id])
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

    func testSelectingOtherApplicationsShowsSingleWindowApplicationsInMRUOrder() {
        let groupedFirst = makeWindow(id: 1, application: 10, name: "App A")
        let groupedSecond = makeWindow(id: 2, application: 10, name: "App A")
        let olderOther = makeWindow(id: 3, application: 20, name: "App B")
        let newerOther = makeWindow(id: 4, application: 30, name: "App C")
        let history = WindowHistory()
        history.recordFocusedWindow(olderOther.id)
        history.recordFocusedWindow(newerOther.id)
        history.recordFocusedWindow(groupedSecond.id)
        let viewModel = makeViewModel(
            windows: [groupedFirst, groupedSecond, olderOther, newerOther],
            history: history
        )
        viewModel.load(resetSelection: true)

        viewModel.selectApplication(.otherApplications)

        XCTAssertEqual(viewModel.windows.map(\.id), [newerOther.id, olderOther.id])
        XCTAssertEqual(viewModel.selectedWindowID, newerOther.id)
    }

    func testApplicationNavigationIncludesOtherApplicationsAfterApplicationTabs() {
        let appAFirst = makeWindow(id: 1, application: 10, name: "App A")
        let other = makeWindow(id: 2, application: 20, name: "App B")
        let appASecond = makeWindow(id: 3, application: 10, name: "App A")
        let viewModel = makeViewModel(windows: [appAFirst, other, appASecond])
        viewModel.load(resetSelection: true)

        viewModel.moveApplicationSelection(.previous)
        XCTAssertEqual(viewModel.selectedApplication, .otherApplications)

        viewModel.moveApplicationSelection(.next)
        XCTAssertEqual(viewModel.selectedApplication, .all)

        viewModel.moveApplicationSelection(.next)
        XCTAssertEqual(
            viewModel.selectedApplication,
            .application(appAFirst.applicationIdentifier)
        )

        viewModel.moveApplicationSelection(.next)
        XCTAssertEqual(viewModel.selectedApplication, .otherApplications)
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
        let appAFirst = makeWindow(id: 1, application: 10, name: "App A")
        let appBFirst = makeWindow(id: 2, application: 20, name: "App B")
        let appASecond = makeWindow(id: 3, application: 10, name: "App A")
        let appBSecond = makeWindow(id: 4, application: 20, name: "App B")
        let viewModel = makeViewModel(
            windows: [appAFirst, appBFirst, appASecond, appBSecond]
        )
        viewModel.load(resetSelection: true)

        viewModel.moveApplicationSelection(.previous)
        XCTAssertEqual(
            viewModel.selectedApplication,
            .application(appBFirst.applicationIdentifier)
        )

        viewModel.moveApplicationSelection(.next)
        XCTAssertEqual(viewModel.selectedApplication, .all)

        viewModel.moveApplicationSelection(.next)
        XCTAssertEqual(
            viewModel.selectedApplication,
            .application(appAFirst.applicationIdentifier)
        )
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
        let appBFirst = makeWindow(id: 2, application: 20, name: "App B")
        let appBSecond = makeWindow(id: 3, application: 20, name: "App B")
        let viewModel = makeViewModel(windows: [appA, appBFirst, appBSecond])
        viewModel.load(resetSelection: true)
        viewModel.selectApplication(.application(appBFirst.applicationIdentifier))

        viewModel.load(resetSelection: true)

        XCTAssertEqual(viewModel.selectedApplication, .all)
        XCTAssertEqual(viewModel.windows.map(\.id), [appA.id, appBFirst.id, appBSecond.id])
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
