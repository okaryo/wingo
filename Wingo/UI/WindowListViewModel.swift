import Foundation

@MainActor
final class WindowListViewModel: ObservableObject {
    enum State {
        case loading
        case permissionRequired
        case loaded
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var windows: [WindowItem] = []
    @Published private(set) var inspectedApplicationCount = 0
    @Published private(set) var inaccessibleApplicationCount = 0

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
        state = .loaded
    }

    func requestPermission() {
        load(promptForPermission: true)
    }

    func openSystemSettings() {
        AccessibilityService.openSystemSettings()
    }
}
