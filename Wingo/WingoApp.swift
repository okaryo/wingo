import SwiftUI

@main
struct WingoApp: App {
    var body: some Scene {
        WindowGroup {
            WindowListView()
                .frame(minWidth: 560, minHeight: 420)
        }
        .defaultSize(width: 680, height: 560)
        .windowResizability(.contentMinSize)
    }
}
