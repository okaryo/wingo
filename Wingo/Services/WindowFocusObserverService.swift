import AppKit
@preconcurrency import ApplicationServices

@MainActor
final class WindowFocusObserverService: NSObject, @unchecked Sendable {
    private struct Registration {
        let observer: AXObserver
        let applicationElement: AXUIElement
    }

    private let history: WindowHistory
    private var registrations: [pid_t: Registration] = [:]
    private var isObservingWorkspace = false

    init(history: WindowHistory) {
        self.history = history
    }

    func startOrRefresh() {
        startObservingWorkspaceIfNeeded()

        guard AccessibilityService.isTrusted(promptIfNeeded: false) else {
            return
        }

        let ownProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        let applications = NSWorkspace.shared.runningApplications.filter { application in
            application.processIdentifier != ownProcessIdentifier
                && !application.isTerminated
                && application.activationPolicy == .regular
        }
        let runningProcessIdentifiers = Set(applications.map(\.processIdentifier))

        for processIdentifier in Array(registrations.keys)
            where !runningProcessIdentifiers.contains(processIdentifier) {
            removeRegistration(for: processIdentifier)
        }

        for application in applications {
            register(application)
        }

        if let frontmostApplication = NSWorkspace.shared.frontmostApplication,
           frontmostApplication.processIdentifier != ownProcessIdentifier {
            recordFocusedWindow(for: frontmostApplication.processIdentifier)
        }
    }

    func stop() {
        if isObservingWorkspace {
            NSWorkspace.shared.notificationCenter.removeObserver(self)
            isObservingWorkspace = false
        }

        for processIdentifier in Array(registrations.keys) {
            removeRegistration(for: processIdentifier)
        }
    }

    private func startObservingWorkspaceIfNeeded() {
        guard !isObservingWorkspace else {
            return
        }

        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidTerminate(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        isObservingWorkspace = true
    }

    private func register(_ application: NSRunningApplication) {
        let processIdentifier = application.processIdentifier
        guard
            registrations[processIdentifier] == nil,
            processIdentifier != ProcessInfo.processInfo.processIdentifier,
            !application.isTerminated,
            application.activationPolicy == .regular
        else {
            return
        }

        var observer: AXObserver?
        guard
            AXObserverCreate(processIdentifier, Self.observerCallback, &observer) == .success,
            let observer
        else {
            return
        }

        let applicationElement = AXUIElementCreateApplication(processIdentifier)
        let registrationError = AXObserverAddNotification(
            observer,
            applicationElement,
            kAXFocusedWindowChangedNotification as CFString,
            Unmanaged.passUnretained(self).toOpaque()
        )
        guard registrationError == .success else {
            return
        }

        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(observer),
            .commonModes
        )
        registrations[processIdentifier] = Registration(
            observer: observer,
            applicationElement: applicationElement
        )
    }

    private func removeRegistration(for processIdentifier: pid_t) {
        guard let registration = registrations.removeValue(forKey: processIdentifier) else {
            return
        }

        AXObserverRemoveNotification(
            registration.observer,
            registration.applicationElement,
            kAXFocusedWindowChangedNotification as CFString
        )
        CFRunLoopRemoveSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(registration.observer),
            .commonModes
        )
    }

    private func recordFocusedWindow(for processIdentifier: pid_t) {
        let applicationElement = registrations[processIdentifier]?.applicationElement
            ?? AXUIElementCreateApplication(processIdentifier)
        var value: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(
                applicationElement,
                kAXFocusedWindowAttribute as CFString,
                &value
            ) == .success,
            let value,
            CFGetTypeID(value) == AXUIElementGetTypeID()
        else {
            return
        }
        let windowElement = unsafeDowncast(value, to: AXUIElement.self)

        history.recordFocusedWindow(
            WindowIdentifier(
                processIdentifier: processIdentifier,
                accessibilityElement: windowElement
            )
        )
    }

    @objc private func applicationDidLaunch(_ notification: Notification) {
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
            as? NSRunningApplication else {
            return
        }
        register(application)
    }

    @objc private func applicationDidTerminate(_ notification: Notification) {
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
            as? NSRunningApplication else {
            return
        }
        removeRegistration(for: application.processIdentifier)
    }

    @objc private func applicationDidActivate(_ notification: Notification) {
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
            as? NSRunningApplication else {
            return
        }

        let ownProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        guard application.processIdentifier != ownProcessIdentifier else {
            return
        }

        register(application)
        recordFocusedWindow(for: application.processIdentifier)
    }

    private static let observerCallback: AXObserverCallback = { _, element, _, userData in
        guard let userData else {
            return
        }

        var processIdentifier: pid_t = 0
        guard AXUIElementGetPid(element, &processIdentifier) == .success else {
            return
        }

        let service = Unmanaged<WindowFocusObserverService>
            .fromOpaque(userData)
            .takeUnretainedValue()
        MainActor.assumeIsolated {
            service.recordFocusedWindow(for: processIdentifier)
        }
    }
}
