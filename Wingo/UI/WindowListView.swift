import SwiftUI

struct WindowListView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = WindowListViewModel()
    @FocusState private var hasKeyboardFocus: Bool

    let onDismiss: () -> Void
    let onActivationFailure: () -> Void

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
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.separator.opacity(0.45), lineWidth: 1)
        }
        .focusable()
        .focused($hasKeyboardFocus)
        .task {
            viewModel.load(promptForPermission: true, resetSelection: true)
            hasKeyboardFocus = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .wingoSwitcherWillShow)) { _ in
            viewModel.load(resetSelection: true)
            hasKeyboardFocus = true
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.load()
            }
        }
        .onKeyPress(.upArrow) {
            viewModel.moveSelection(.up)
            return .handled
        }
        .onKeyPress(.downArrow) {
            viewModel.moveSelection(.down)
            return .handled
        }
        .onKeyPress(.return) {
            guard viewModel.selectedWindowID != nil else {
                return .ignored
            }
            activateSelectedWindow()
            return .handled
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
        .alert(item: $viewModel.activationAlert) { alert in
            Alert(
                title: Text("Couldn’t Switch Window"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
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
        Group {
            if viewModel.windows.isEmpty {
                ContentUnavailableView(
                    "No Windows Found",
                    systemImage: "macwindow",
                    description: Text("Open a window in another application, then refresh the list.")
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(viewModel.windows) { window in
                                windowRow(window)
                                    .id(window.id)
                            }
                        }
                        .padding(4)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: viewModel.selectedWindowID) { _, selectedWindowID in
                        guard let selectedWindowID else {
                            return
                        }
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(selectedWindowID, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private func windowRow(_ window: WindowItem) -> some View {
        let isSelected = viewModel.selectedWindowID == window.id

        return HStack(spacing: 12) {
            applicationIcon(for: window)

            VStack(alignment: .leading, spacing: 2) {
                Text(window.windowTitle)
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(window.applicationName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectedWindowID = window.id
            hasKeyboardFocus = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
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

    private func activateSelectedWindow() {
        onDismiss()
        if !viewModel.activateSelectedWindow() {
            onActivationFailure()
        }
    }
}
