import Foundation

@MainActor
final class WindowListViewModel: ObservableObject {
    enum SelectionDirection {
        case up
        case down
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
    @Published private(set) var inspectedApplicationCount = 0
    @Published private(set) var inaccessibleApplicationCount = 0
    @Published var selectedWindowID: WindowIdentifier?
    @Published var activationAlert: ActivationAlert?
    private let windowHistory: WindowHistory

    init(windowHistory: WindowHistory) {
        self.windowHistory = windowHistory
    }

    func load(promptForPermission: Bool = false, resetSelection: Bool = false) {
        guard AccessibilityService.isTrusted(promptIfNeeded: promptForPermission) else {
            windows = []
            selectedWindowID = nil
            state = .permissionRequired
            return
        }

        state = .loading
        let result = WindowService.discoverWindows()
        windows = windowHistory.orderedWindows(result.windows)
        inspectedApplicationCount = result.inspectedApplicationCount
        inaccessibleApplicationCount = result.inaccessibleApplicationCount
        if !resetSelection,
           let selectedWindowID,
           windows.contains(where: { $0.id == selectedWindowID }) {
            self.selectedWindowID = selectedWindowID
        } else {
            selectedWindowID = windowHistory.initialSelection(in: windows)
        }
        state = .loaded
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
}
