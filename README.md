# Wingo

Wingo is a keyboard-first window switcher for macOS.

## Current status

Phase 1 is implemented. The development UI can request Accessibility permission and list the
currently open windows, including each application icon and window title. Window activation,
the global shortcut, the switcher panel, and MRU ordering are planned for later phases.

## Requirements

- macOS 15.0 or later
- Xcode 26 or later for development

## Development

1. Open `Wingo.xcodeproj` in Xcode.
2. Select the `Wingo` scheme and run the app.
3. Grant Accessibility permission when prompted.
4. Return to Wingo or press `Cmd + R` in the app to refresh the window list.

Wingo currently keeps its Dock icon and a normal window to make Phase 1 development and
verification easier.

## Accessibility Permission

Wingo uses the macOS Accessibility API to discover windows owned by other applications. macOS
requires explicit user permission for this access. Enable Wingo under **System Settings → Privacy
& Security → Accessibility**.

## Privacy

Wingo does not perform network communication or send window information, titles, or usage data
outside the Mac.

## Current limitations

- The Phase 1 UI only lists windows; selecting a window does not activate it yet.
- Some applications expose incomplete or unusual window information through the Accessibility API.
- Window ordering is not MRU-based yet.
- Wingo is not yet packaged as a signed or notarized DMG.
