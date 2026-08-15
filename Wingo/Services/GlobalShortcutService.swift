import Foundation
@preconcurrency import Carbon.HIToolbox

enum GlobalShortcutError: LocalizedError {
    case eventHandlerRegistrationFailed(OSStatus)
    case hotKeyRegistrationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case let .eventHandlerRegistrationFailed(status):
            return "Wingo could not install its shortcut event handler (OSStatus \(status))."
        case let .hotKeyRegistrationFailed(status):
            if status == eventHotKeyExistsErr {
                return "Option + Space is already registered by another application."
            }
            return "Wingo could not register Option + Space (OSStatus \(status))."
        }
    }
}

@MainActor
final class GlobalShortcutService: @unchecked Sendable {
    private static let signature: OSType = 0x5749_4E47 // "WING"
    private static let identifier: UInt32 = 1

    private var eventHandlerReference: EventHandlerRef?
    private var hotKeyReference: EventHotKeyRef?
    private let onShortcut: () -> Void

    init(onShortcut: @escaping () -> Void) {
        self.onShortcut = onShortcut
    }

    func start() throws {
        guard hotKeyReference == nil else {
            return
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            Self.eventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerReference
        )
        guard handlerStatus == noErr else {
            eventHandlerReference = nil
            throw GlobalShortcutError.eventHandlerRegistrationFailed(handlerStatus)
        }

        let hotKeyID = EventHotKeyID(
            signature: Self.signature,
            id: Self.identifier
        )
        let modifiers = UInt32(optionKey)
        let registrationStatus = RegisterEventHotKey(
            UInt32(kVK_Space),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyReference
        )
        guard registrationStatus == noErr else {
            if let eventHandlerReference {
                RemoveEventHandler(eventHandlerReference)
            }
            eventHandlerReference = nil
            hotKeyReference = nil
            throw GlobalShortcutError.hotKeyRegistrationFailed(registrationStatus)
        }
    }

    func stop() {
        if let hotKeyReference {
            UnregisterEventHotKey(hotKeyReference)
            self.hotKeyReference = nil
        }

        if let eventHandlerReference {
            RemoveEventHandler(eventHandlerReference)
            self.eventHandlerReference = nil
        }
    }

    private func handleShortcut() {
        onShortcut()
    }

    private static let eventHandler: EventHandlerUPP = { _, event, userData in
        guard let event, let userData else {
            return OSStatus(eventNotHandledErr)
        }

        var hotKeyID = EventHotKeyID()
        let parameterStatus = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        guard
            parameterStatus == noErr,
            hotKeyID.signature == signature,
            hotKeyID.id == identifier
        else {
            return OSStatus(eventNotHandledErr)
        }

        let service = Unmanaged<GlobalShortcutService>
            .fromOpaque(userData)
            .takeUnretainedValue()
        MainActor.assumeIsolated {
            service.handleShortcut()
        }
        return noErr
    }
}
