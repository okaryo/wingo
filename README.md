# Wingo

Wingo is a keyboard-first window switcher for macOS.

## Current status

Phase 2 is implemented. The development UI can request Accessibility permission, list the
currently open windows, and activate a selected window. The global shortcut, switcher panel, and
MRU ordering are planned for later phases.

## Requirements

- macOS 15.0 or later
- Xcode 26 or later for development

## Development

1. Open `Wingo.xcodeproj` in Xcode.
2. Select the `Wingo` scheme and run the app.
3. Grant Accessibility permission when prompted.
4. Return to Wingo or press `Cmd + R` in the app to refresh the window list.
5. Select a window and click **Activate Window**, or double-click a window, to switch to it.

Wingo currently keeps its Dock icon and a normal window to make early-phase development and
verification easier.

## Accessibility Permission

Wingo uses the macOS Accessibility API to discover windows owned by other applications. macOS
requires explicit user permission for this access. Enable Wingo under **System Settings → Privacy
& Security → Accessibility**.

## Phase 2 manual verification

After granting Accessibility permission, verify window activation with the development UI:

1. Open multiple windows in the same application, such as VS Code, Chrome, Finder, or Terminal.
2. Select each window in Wingo and click **Activate Window**; confirm the exact selected window is
   raised and focused rather than only activating its application.
3. Minimize a target window and activate it from Wingo; confirm it is restored and focused.
4. Close a window after refreshing Wingo, then try to activate the stale entry; confirm Wingo shows
   an error instead of crashing.
5. Quit a target application after refreshing Wingo and confirm activating its stale entry is
   handled safely.

## Privacy

Wingo does not perform network communication or send window information, titles, or usage data
outside the Mac.

## Current limitations

- The Phase 2 UI is a development interface, not the final floating switcher panel.
- Some applications expose incomplete or unusual window information through the Accessibility API.
- Window ordering is not MRU-based yet.
- Wingo is not yet packaged as a signed or notarized DMG.
