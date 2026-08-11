# Wingo

Wingo is a keyboard-first window switcher for macOS.

## Current status

Phase 6 is implemented. `Cmd + Ctrl + ↑` opens a floating keyboard-controlled switcher panel with
in-memory MRU ordering, and `Cmd + 1` through `Cmd + 9` switch directly to the corresponding
visible window.

## Requirements

- macOS 15.0 or later
- Xcode 26 or later for development

## Development

1. Open `Wingo.xcodeproj` in Xcode.
2. Select the `Wingo` scheme and run the app.
3. Grant Accessibility permission when prompted.
4. Move away from Wingo, then press `Cmd + Ctrl + ↑` to open the switcher globally.
5. Use `↑` / `↓` to select a window, `Enter` to switch, `Cmd + 1...9` to switch directly, or `Esc`
   to close the panel.

Wingo currently keeps its Dock icon to make early-phase development and verification easier. The
switcher itself uses a titleless floating panel.

Run the `WingoTests` tests with **Product → Test** in Xcode. These tests cover in-memory MRU
ordering, fallback ordering, initial selection behavior, and direct-shortcut index mapping.

## Accessibility Permission

Wingo uses the macOS Accessibility API to discover windows owned by other applications. macOS
requires explicit user permission for this access. Enable Wingo under **System Settings → Privacy
& Security → Accessibility**.

## Phase 2 manual verification

After granting Accessibility permission, verify window activation with the switcher UI:

1. Open multiple windows in the same application, such as VS Code, Chrome, Finder, or Terminal.
2. Select each window in Wingo and press `Enter`; confirm the exact selected window is
   raised and focused rather than only activating its application.
3. Minimize a target window and activate it from Wingo; confirm it is restored and focused.
4. Close a window after refreshing Wingo, then try to activate the stale entry; confirm Wingo shows
   an error instead of crashing.
5. Quit a target application after refreshing Wingo and confirm activating its stale entry is
   handled safely.

## Phase 3 manual verification

1. Launch Wingo, then dismiss its panel with `Esc` without quitting the application.
2. Focus another application and press `Cmd + Ctrl + ↑`.
3. Confirm Wingo reappears, becomes ready for input, and refreshes its window list.
4. Repeat the shortcut from several applications and after closing or opening target windows.
5. If another application already owns the shortcut, confirm Wingo shows a registration error
   instead of silently failing.

## Phase 4 manual verification

1. Press `Cmd + Ctrl + ↑` and confirm a titleless floating panel appears near the center of the
   display containing the mouse pointer.
2. Confirm the first window is selected when the panel opens.
3. Use `↑` and `↓` to move the selection, including wrapping at both ends of the list.
4. Press `Enter` and confirm the panel disappears before the selected window receives focus.
5. Press `Esc` and confirm the panel disappears without switching windows.
6. Confirm long window titles stay on one line and the panel follows Light and Dark appearances.

## Phase 5 manual verification

1. Focus three or more windows in a known order, including multiple windows from the same app.
2. Open Wingo and confirm the most recently focused windows appear first.
3. Confirm the currently focused window remains listed, but the previous different window is
   initially selected so `Cmd + Ctrl + ↑`, then `Enter`, returns to it.
4. Switch back and forth using Wingo and confirm the MRU order updates each time.
5. Open or close windows and confirm untracked windows use a stable fallback order without crashes.
6. Quit and relaunch Wingo and confirm it starts safely with a fresh in-memory history.

## Phase 6 manual verification

1. Open at least ten windows, then open Wingo and confirm only the first nine rows show shortcut
   labels from `⌘1` through `⌘9`.
2. Press each available `Cmd + 1...9` shortcut and confirm Wingo closes before switching directly
   to the window on the corresponding row.
3. Open Wingo with fewer than nine windows and press a number without a corresponding row; confirm
   the panel stays open and no window is switched.
4. Change the MRU order by focusing different windows, reopen Wingo, and confirm the number
   shortcuts follow the newly displayed order.

## Privacy

Wingo does not perform network communication or send window information, titles, or usage data
outside the Mac.

## Current limitations

- MRU history is kept in memory and resets when Wingo quits.
- Some applications expose incomplete or unusual window information through the Accessibility API.
- Wingo is not yet packaged as a signed or notarized DMG.
