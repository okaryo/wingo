# Wingo

Wingo is a keyboard-first window switcher for macOS. It prioritizes recently used windows from
running applications so you can find and focus a specific window without reaching for the mouse.

## Features

- Open the switcher from anywhere with a global keyboard shortcut.
- Stay out of the Dock and application switcher while running in the background.
- Switch directly to an individual window, including another window from the same application.
- Keep windows in MRU order while placing the currently focused window last.
- Filter windows using tabs for applications that have multiple windows open, plus an icon-only
  Other Apps tab for applications with a single window.
- Navigate entirely with arrow keys or Vim-style `h`, `j`, `k`, and `l` keys.
- Jump to one of the first nine visible windows with `Command + 1` through `Command + 9`.
- Restore minimized windows when switching to them.
- Open on the display containing the pointer and work across macOS Spaces and full-screen apps.
- Follow the system Light and Dark appearances.

## Requirements

- macOS 15.0 or later
- Accessibility permission for discovering and focusing windows
- Xcode 26 or later when building from source

## Getting started

Wingo is currently distributed by building it from source:

1. Open `Wingo.xcodeproj` in Xcode.
2. Select the `Wingo` scheme and run the app.
3. When prompted, allow Wingo under **System Settings → Privacy & Security → Accessibility**.
4. Focus another application and press `Command + Control + Up Arrow` to open Wingo.

The Accessibility permission is required because macOS does not otherwise allow Wingo to inspect
or focus windows owned by other applications.

## Keyboard controls

| Shortcut | Action |
| --- | --- |
| `Command + Control + Up Arrow` | Open Wingo |
| `Up Arrow` / `Down Arrow` | Move the window selection |
| `k` / `j` | Move the window selection up or down |
| `Left Arrow` / `Right Arrow` | Move between application tabs |
| `h` / `l` | Move between application tabs |
| `Command + Shift + [` / `]` | Move between application tabs |
| `Return` | Switch to the selected window |
| `Escape` | Close Wingo and return to the previous application |
| `Command + 1` … `9` | Switch to the corresponding visible window |
| `Command + Q` | Quit Wingo while the switcher is open |

Window and application-tab navigation wraps at both ends. The Other Apps tab groups applications
that each have a single window and is identified by an ellipsis icon. Application tabs are hidden
when every application has only one window. Number shortcuts always follow the currently visible,
filtered list.

## How window ordering works

Wingo observes focused-window changes while it is running and places windows in most-recently-used
order, except that the currently focused window is placed last. When the switcher opens, the
previous window is therefore first, initially selected, and assigned to `Command + 1`. Application
tabs follow the same window ordering.

MRU history is currently stored in memory and resets when Wingo quits. Windows that have not yet
been observed retain their discovery order.

## Development

### Build and run

1. Open `Wingo.xcodeproj` in Xcode.
2. Select a development team for the Wingo target under **Signing & Capabilities** if necessary.
3. Select the `Wingo` scheme and run the app.
4. Grant Accessibility permission when prompted.

Wingo is a native macOS application built with SwiftUI and AppKit. It uses the macOS Accessibility
API to discover and activate windows and the Carbon hot-key API to register its global shortcut.

### Project structure

```text
Wingo/
├── Models/      Window and shortcut data types
├── Services/    Window discovery, activation, history, observation, and global shortcut handling
├── UI/          SwiftUI switcher interface and AppKit panel management
├── AppDelegate.swift
└── WingoApp.swift
WingoTests/      Unit tests
```

### Tests

Run the `WingoTests` test target with **Product → Test** in Xcode, or from the command line:

```sh
xcodebuild test -project Wingo.xcodeproj -scheme Wingo -destination 'platform=macOS'
```

The tests cover MRU and fallback ordering, initial selection, application filtering and tab
navigation, and direct number-shortcut mapping.

## Troubleshooting

### Accessibility permission does not stay enabled

If Wingo was previously run with a different or ad-hoc signature, macOS may retain a stale
permission record. Reset only Wingo's Accessibility entry, then run the app and grant permission
again:

```sh
tccutil reset Accessibility studio.okaryo.wingo
```

Avoid resetting Accessibility without the bundle identifier because that removes approvals for
other applications too. Using a stable development signature also helps permission survive normal
rebuilds.

### The global shortcut does not work

Another application may already own `Command + Control + Up Arrow`. Wingo displays a registration
error when macOS refuses the shortcut; close or reconfigure the conflicting application and
relaunch Wingo.

### Some windows are missing

Applications expose their windows through the macOS Accessibility API. Some applications provide
incomplete or unusual window information, so their windows may not appear or behave as expected.

## Privacy

Wingo does not perform network communication. Window titles, application information, and usage
history remain on the Mac, and MRU history exists only in memory for the lifetime of the process.

## Current limitations

- The global shortcut is not configurable.
- MRU history resets when Wingo quits.
- Some applications expose incomplete or unusual window information through the Accessibility API.
- Prebuilt, Developer ID-signed and notarized releases are not currently provided.
