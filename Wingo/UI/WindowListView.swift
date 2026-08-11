import SwiftUI

struct WindowListView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = WindowListViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading windows…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .permissionRequired:
                permissionView
            case .loaded:
                windowList
            }
        }
        .navigationTitle("Wingo — Phase 1")
        .task {
            viewModel.load(promptForPermission: true)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.load()
            }
        }
    }

    private var permissionView: some View {
        ContentUnavailableView {
            Label("Accessibility Permission Required", systemImage: "hand.raised.fill")
        } description: {
            Text(
                "Wingo needs Accessibility permission to discover and switch between windows. "
                    + "Enable Wingo in System Settings → Privacy & Security → Accessibility."
            )
        } actions: {
            HStack {
                Button("Request Permission") {
                    viewModel.requestPermission()
                }

                Button("Open System Settings") {
                    viewModel.openSystemSettings()
                }
            }
        }
    }

    private var windowList: some View {
        VStack(spacing: 0) {
            if viewModel.windows.isEmpty {
                ContentUnavailableView(
                    "No Windows Found",
                    systemImage: "macwindow",
                    description: Text("Open a window in another application, then refresh the list.")
                )
            } else {
                List(viewModel.windows) { window in
                    HStack(spacing: 12) {
                        applicationIcon(for: window)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(window.windowTitle)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Text(window.applicationName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 3)
                }
            }

            Divider()

            HStack {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Refresh") {
                    viewModel.load()
                }
                .keyboardShortcut("r", modifiers: .command)
            }
            .padding(12)
        }
    }

    @ViewBuilder
    private func applicationIcon(for window: WindowItem) -> some View {
        if let icon = window.applicationIcon {
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        } else {
            Image(systemName: "app")
                .font(.title2)
                .frame(width: 32, height: 32)
                .foregroundStyle(.secondary)
        }
    }

    private var statusText: String {
        var text = "\(viewModel.windows.count) windows from \(viewModel.inspectedApplicationCount) applications"
        if viewModel.inaccessibleApplicationCount > 0 {
            text += " · \(viewModel.inaccessibleApplicationCount) applications unavailable"
        }
        return text
    }
}
