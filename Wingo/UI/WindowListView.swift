import SwiftUI

struct WindowListView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: WindowListViewModel
    @FocusState private var hasKeyboardFocus: Bool
    @State private var listPresentationID = 0

    let onDismiss: () -> Void
    let onPrepareForActivation: () -> Void
    let onActivationSuccess: () -> Void
    let onActivationFailure: () -> Void
    let onQuit: () -> Void

    init(
        windowHistory: WindowHistory,
        onDismiss: @escaping () -> Void,
        onPrepareForActivation: @escaping () -> Void,
        onActivationSuccess: @escaping () -> Void,
        onActivationFailure: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: WindowListViewModel(windowHistory: windowHistory)
        )
        self.onDismiss = onDismiss
        self.onPrepareForActivation = onPrepareForActivation
        self.onActivationSuccess = onActivationSuccess
        self.onActivationFailure = onActivationFailure
        self.onQuit = onQuit
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading windows…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .permissionRequired:
                permissionView
            case .loaded:
                loadedContent
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.separator.opacity(0.45), lineWidth: 1)
        }
        .focusable()
        .focusEffectDisabled()
        .focused($hasKeyboardFocus)
        .task {
            viewModel.load(promptForPermission: true, resetSelection: true)
            hasKeyboardFocus = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .wingoSwitcherWillShow)) { _ in
            viewModel.load(resetSelection: true)
            listPresentationID += 1
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
        .onKeyPress(.leftArrow) {
            viewModel.moveApplicationSelection(.previous)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            viewModel.moveApplicationSelection(.next)
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
        .onKeyPress(phases: [.down, .repeat]) { keyPress in
            handleKeyPress(keyPress)
        }
        .alert(item: $viewModel.activationAlert) { alert in
            Alert(
                title: Text("Couldn’t Switch Window"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var loadedContent: some View {
        VStack(spacing: 8) {
            if !viewModel.applicationTabs.isEmpty {
                applicationHeader

                Divider()
            }

            windowList
        }
    }

    private var applicationHeader: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    applicationTab(
                        selection: .all,
                        title: "All",
                        icon: nil,
                        systemImage: "square.grid.2x2",
                        isAll: true,
                        windowCount: viewModel.allWindowCount
                    )

                    ForEach(viewModel.applicationTabs) { tab in
                        applicationTab(
                            selection: .application(tab.id),
                            title: tab.applicationName,
                            icon: tab.applicationIcon,
                            systemImage: "app",
                            isAll: false,
                            windowCount: tab.windowCount
                        )
                    }

                    if viewModel.hasOtherApplicationsTab {
                        applicationTab(
                            selection: .otherApplications,
                            title: "Other Apps",
                            icon: nil,
                            systemImage: "ellipsis",
                            isAll: false,
                            windowCount: viewModel.otherApplicationWindowCount
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .onChange(of: viewModel.selectedApplication) { _, selectedApplication in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo(selectedApplication, anchor: .center)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func applicationTab(
        selection: WindowListViewModel.ApplicationSelection,
        title: String,
        icon: NSImage?,
        systemImage: String,
        isAll: Bool,
        windowCount: Int
    ) -> some View {
        let isSelected = viewModel.selectedApplication == selection

        return Button {
            viewModel.selectApplication(selection)
            hasKeyboardFocus = true
        } label: {
            ZStack(alignment: .topTrailing) {
                if let icon {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 25, weight: .medium))
                        .frame(width: 34, height: 34)
                }

                if isAll || selection == .otherApplications || windowCount > 1 {
                    Text("\(windowCount)")
                        .font(.system(size: 9, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(
                            isAll && !isSelected ? Color.white : Color.secondary
                        )
                        .padding(.horizontal, 4)
                        .frame(minWidth: 16, minHeight: 16)
                        .background {
                            Capsule()
                                .fill(
                                    isAll && !isSelected
                                        ? AnyShapeStyle(Color.accentColor)
                                        : AnyShapeStyle(.regularMaterial)
                                )
                        }
                        .overlay {
                            if !isAll {
                                Capsule()
                                    .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 0.5)
                            }
                        }
                        .offset(x: 7, y: -6)
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .id(selection)
        .help(title)
        .accessibilityLabel("\(title), \(windowCount) windows")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 4) {
                            ForEach(
                                Array(viewModel.windows.enumerated()),
                                id: \.element.id
                            ) { index, window in
                                windowRow(
                                    window,
                                    shortcutNumber: WindowShortcut.number(forListIndex: index)
                                )
                                    .id(window.id)
                            }
                        }
                        .padding(4)
                    }
                    .id(listPresentationID)
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

    private func windowRow(_ window: WindowItem, shortcutNumber: Int?) -> some View {
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

            if let shortcutNumber {
                Text("⌘\(shortcutNumber)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : Color.secondary)
                    .accessibilityLabel("Command \(shortcutNumber)")
            }
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
        onPrepareForActivation()
        if viewModel.activateSelectedWindow() {
            onActivationSuccess()
        } else {
            onActivationFailure()
        }
    }

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        let modifiers = keyPress.modifiers
        let hasCommand = modifiers.contains(.command)
        let hasShift = modifiers.contains(.shift)
        let hasOption = modifiers.contains(.option)
        let hasControl = modifiers.contains(.control)

        if hasCommand, hasShift, !hasOption, !hasControl {
            switch keyPress.characters {
            case "[", "{":
                viewModel.moveApplicationSelection(.previous)
                return .handled
            case "]", "}":
                viewModel.moveApplicationSelection(.next)
                return .handled
            default:
                return .ignored
            }
        }

        if hasCommand, !hasShift, !hasOption, !hasControl,
           let shortcutNumber = Int(keyPress.characters),
           viewModel.selectWindow(forShortcutNumber: shortcutNumber) {
            activateSelectedWindow()
            return .handled
        }

        if hasCommand, !hasShift, !hasOption, !hasControl,
           keyPress.characters.lowercased() == "q" {
            onQuit()
            return .handled
        }

        guard !hasCommand, !hasShift, !hasOption, !hasControl else {
            return .ignored
        }

        switch keyPress.characters.lowercased() {
        case "h":
            viewModel.moveApplicationSelection(.previous)
        case "j":
            viewModel.moveSelection(.down)
        case "k":
            viewModel.moveSelection(.up)
        case "l":
            viewModel.moveApplicationSelection(.next)
        default:
            return .ignored
        }
        return .handled
    }
}
