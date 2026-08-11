import Foundation

@MainActor
final class WindowListViewModel: ObservableObject {
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

    func load(promptForPermission: Bool = false) {
        guard AccessibilityService.isTrusted(promptIfNeeded: promptForPermission) else {
            windows = []
            state = .permissionRequired
            return
        }

        state = .loading
        let result = WindowService.discoverWindows()
        windows = result.windows
        inspectedApplicationCount = result.inspectedApplicationCount
        inaccessibleApplicationCount = result.inaccessibleApplicationCount
        if let selectedWindowID, windows.contains(where: { $0.id == selectedWindowID }) {
            self.selectedWindowID = selectedWindowID
        } else {
            selectedWindowID = nil
        }
        state = .loaded
    }

    func requestPermission() {
        load(promptForPermission: true)
    }

    func openSystemSettings() {
        AccessibilityService.openSystemSettings()
    }

    func activateSelectedWindow() {
        guard
            let selectedWindowID,
            let window = windows.first(where: { $0.id == selectedWindowID })
        else {
            return
        }

        activate(window)
    }

    func activate(_ window: WindowItem) {
        switch WindowActivationService.activate(window) {
        case .success:
            break
        case let .failure(error):
            activationAlert = ActivationAlert(
                message: error.errorDescription ?? "The selected window could not be activated."
            )
        }
    }
}
