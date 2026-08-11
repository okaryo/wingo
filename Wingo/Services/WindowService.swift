import AppKit
import ApplicationServices

struct WindowDiscoveryResult {
    let windows: [WindowItem]
    let inspectedApplicationCount: Int
    let inaccessibleApplicationCount: Int
}

enum WindowService {
    static func discoverWindows() -> WindowDiscoveryResult {
        let ownProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        let applications = NSWorkspace.shared.runningApplications.filter { application in
            application.processIdentifier != ownProcessIdentifier
                && !application.isTerminated
                && application.activationPolicy == .regular
        }

        var windows: [WindowItem] = []
        var inaccessibleApplicationCount = 0

        for application in applications {
            let applicationElement = AXUIElementCreateApplication(application.processIdentifier)

            guard let applicationWindows: [AXUIElement] = copyAttribute(
                kAXWindowsAttribute,
                from: applicationElement
            ) else {
                inaccessibleApplicationCount += 1
                continue
            }

            let applicationName = application.localizedName ?? "Unknown Application"

            for windowElement in applicationWindows where isSwitchableWindow(windowElement) {
                let rawTitle: String? = copyAttribute(kAXTitleAttribute, from: windowElement)
                let title = displayTitle(rawTitle, applicationName: applicationName)
                let identifier = WindowIdentifier(
                    processIdentifier: application.processIdentifier,
                    accessibilityElement: windowElement
                )

                windows.append(
                    WindowItem(
                        id: identifier,
                        processIdentifier: application.processIdentifier,
                        applicationName: applicationName,
                        applicationIcon: application.icon,
                        windowTitle: title,
                        accessibilityReference: AccessibilityWindowReference(element: windowElement)
                    )
                )
            }
        }

        return WindowDiscoveryResult(
            windows: windows,
            inspectedApplicationCount: applications.count,
            inaccessibleApplicationCount: inaccessibleApplicationCount
        )
    }

    private static func isSwitchableWindow(_ element: AXUIElement) -> Bool {
        let role: String? = copyAttribute(kAXRoleAttribute, from: element)
        guard role == (kAXWindowRole as String) else {
            return false
        }

        let size: AXValue? = copyAttribute(kAXSizeAttribute, from: element)
        if let size, size.axSize == .zero {
            return false
        }

        return true
    }

    private static func displayTitle(_ title: String?, applicationName: String) -> String {
        guard let title else {
            return applicationName
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? applicationName : trimmedTitle
    }

    private static func copyAttribute<Value>(
        _ attribute: String,
        from element: AXUIElement
    ) -> Value? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

        guard error == .success else {
            return nil
        }

        return value as? Value
    }
}

private extension AXValue {
    var axSize: CGSize? {
        guard AXValueGetType(self) == .cgSize else {
            return nil
        }

        var size = CGSize.zero
        return AXValueGetValue(self, .cgSize, &size) ? size : nil
    }
}
