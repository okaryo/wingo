import AppKit

@MainActor
final class WindowListViewModel: ObservableObject {
    enum SelectionDirection {
        case up
        case down
    }

    enum ApplicationSelectionDirection {
        case previous
        case next
    }

    enum ApplicationSelection: Hashable {
        case all
        case application(ApplicationIdentifier)
    }

    struct ApplicationTab: Identifiable {
        let id: ApplicationIdentifier
        let applicationName: String
        let applicationIcon: NSImage?
        let windowCount: Int
    }

    struct ActivationAlert: Identifiable {
        let id = UUID()
        let message: String
    }

    enum State {
        case loading
        case permissionRequired
        case loaded
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var windows: [WindowItem] = []
    @Published private(set) var applicationTabs: [ApplicationTab] = []
    @Published private(set) var selectedApplication: ApplicationSelection = .all
    @Published private(set) var inspectedApplicationCount = 0
    @Published private(set) var inaccessibleApplicationCount = 0
    @Published var selectedWindowID: WindowIdentifier?
    @Published var activationAlert: ActivationAlert?
    private let windowHistory: WindowHistory
    private let discoverWindows: () -> WindowDiscoveryResult
    private let isAccessibilityTrusted: (Bool) -> Bool
    private var allWindows: [WindowItem] = []

    init(
        windowHistory: WindowHistory,
        discoverWindows: @escaping () -> WindowDiscoveryResult = WindowService.discoverWindows,
        isAccessibilityTrusted: @escaping (Bool) -> Bool = {
            AccessibilityService.isTrusted(promptIfNeeded: $0)
        }
    ) {
        self.windowHistory = windowHistory
        self.discoverWindows = discoverWindows
        self.isAccessibilityTrusted = isAccessibilityTrusted
    }

    var allWindowCount: Int { allWindows.count }

    func load(promptForPermission: Bool = false, resetSelection: Bool = false) {
        guard isAccessibilityTrusted(promptForPermission) else {
            allWindows = []
            windows = []
            applicationTabs = []
            selectedApplication = .all
            selectedWindowID = nil
            state = .permissionRequired
            return
        }

        state = .loading
        let result = discoverWindows()
        allWindows = windowHistory.orderedWindows(result.windows)
        applicationTabs = Self.makeApplicationTabs(from: allWindows)
        inspectedApplicationCount = result.inspectedApplicationCount
        inaccessibleApplicationCount = result.inaccessibleApplicationCount

        if resetSelection || !isSelectedApplicationAvailable {
            selectedApplication = .all
        }
        updateVisibleWindows()

        if !resetSelection,
           let selectedWindowID,
           windows.contains(where: { $0.id == selectedWindowID }) {
            self.selectedWindowID = selectedWindowID
        } else {
            selectedWindowID = windowHistory.initialSelection(in: windows)
        }
        state = .loaded
    }

    func selectApplication(_ selection: ApplicationSelection) {
        guard selection == .all || applicationTabs.contains(where: {
            selection == .application($0.id)
        }) else {
            return
        }

        let isChangingApplication = selection != selectedApplication
        selectedApplication = selection
        updateVisibleWindows()

        if isChangingApplication {
            selectedWindowID = windows.first?.id
            return
        }

        if let selectedWindowID,
           windows.contains(where: { $0.id == selectedWindowID }) {
            return
        }
        selectedWindowID = windowHistory.initialSelection(in: windows)
    }

    func moveApplicationSelection(_ direction: ApplicationSelectionDirection) {
        let selections = [ApplicationSelection.all]
            + applicationTabs.map { ApplicationSelection.application($0.id) }
        guard !selections.isEmpty else {
            return
        }

        let currentIndex = selections.firstIndex(of: selectedApplication) ?? 0
        let nextIndex: Int
        switch direction {
        case .previous:
            nextIndex = currentIndex == 0 ? selections.count - 1 : currentIndex - 1
        case .next:
            nextIndex = currentIndex == selections.count - 1 ? 0 : currentIndex + 1
        }
        selectApplication(selections[nextIndex])
    }

    func requestPermission() {
        load(promptForPermission: true)
    }

    func openSystemSettings() {
        AccessibilityService.openSystemSettings()
    }

    func moveSelection(_ direction: SelectionDirection) {
        guard !windows.isEmpty else {
            selectedWindowID = nil
            return
        }

        guard
            let selectedWindowID,
            let currentIndex = windows.firstIndex(where: { $0.id == selectedWindowID })
        else {
            self.selectedWindowID = windows.first?.id
            return
        }

        let nextIndex: Int
        switch direction {
        case .up:
            nextIndex = currentIndex == 0 ? windows.count - 1 : currentIndex - 1
        case .down:
            nextIndex = currentIndex == windows.count - 1 ? 0 : currentIndex + 1
        }
        self.selectedWindowID = windows[nextIndex].id
    }

    @discardableResult
    func selectWindow(forShortcutNumber number: Int) -> Bool {
        guard let index = WindowShortcut.listIndex(for: number, windowCount: windows.count) else {
            return false
        }

        selectedWindowID = windows[index].id
        return true
    }

    @discardableResult
    func activateSelectedWindow() -> Bool {
        guard
            let selectedWindowID,
            let window = windows.first(where: { $0.id == selectedWindowID })
        else {
            return false
        }

        return activate(window)
    }

    @discardableResult
    func activate(_ window: WindowItem) -> Bool {
        switch WindowActivationService.activate(window) {
        case .success:
            windowHistory.recordFocusedWindow(window.id)
            return true
        case let .failure(error):
            activationAlert = ActivationAlert(
                message: error.errorDescription ?? "The selected window could not be activated."
            )
            return false
        }
    }

    private var isSelectedApplicationAvailable: Bool {
        switch selectedApplication {
        case .all:
            return true
        case let .application(identifier):
            return applicationTabs.contains(where: { $0.id == identifier })
        }
    }

    private func updateVisibleWindows() {
        switch selectedApplication {
        case .all:
            windows = allWindows
        case let .application(identifier):
            windows = allWindows.filter { $0.applicationIdentifier == identifier }
        }
    }

    private static func makeApplicationTabs(from windows: [WindowItem]) -> [ApplicationTab] {
        var tabIndexes: [ApplicationIdentifier: Int] = [:]
        var tabs: [ApplicationTab] = []

        for window in windows {
            if let index = tabIndexes[window.applicationIdentifier] {
                let existingTab = tabs[index]
                tabs[index] = ApplicationTab(
                    id: existingTab.id,
                    applicationName: existingTab.applicationName,
                    applicationIcon: existingTab.applicationIcon,
                    windowCount: existingTab.windowCount + 1
                )
            } else {
                tabIndexes[window.applicationIdentifier] = tabs.count
                tabs.append(
                    ApplicationTab(
                        id: window.applicationIdentifier,
                        applicationName: window.applicationName,
                        applicationIcon: window.applicationIcon,
                        windowCount: 1
                    )
                )
            }
        }

        return tabs
    }
}
