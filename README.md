# Desktop Display

Desktop Display is a tiny macOS utility that lives in the menu bar and shows the index of the currently active desktop Space. It is built with SwiftUI and a simple observable helper that mirrors the state Mission Control keeps internally, so the number updates as you swipe between Spaces or displays.

## Features

- Menu bar menu item that renders the current desktop index using a monospaced label.
- Compact popover panel with the desktop number, a manual refresh button, and a quit shortcut.
- Background observer that listens for `NSWorkspace.activeSpaceDidChangeNotification` and falls back to light polling to stay in sync.

> ⚠️ **Heads up:** The app relies on private CoreGraphics/SkyLight symbols (`CGSCopyManagedDisplaySpaces`, etc.). This means it is not suitable for Mac App Store distribution and could break on future macOS releases.

## Requirements

- macOS 13.0 (Ventura) or later.
- Xcode 15.4 or newer (the project currently targets the macOS 15 SDK).

## Building and Running

1. Open `desktop-display.xcodeproj` in Xcode.
2. Select the `desktop-display` scheme and build/run.  
   Or build from the command line:
   ```bash
   xcodebuild -project desktop-display.xcodeproj -scheme desktop-display -configuration Debug -sdk macosx build
   ```

On launch, the app appears in the menu bar only (the Dock icon is hidden via `LSUIElement`). Choose the menu bar extra to see the popover controls.

## Project Structure

- `desktop_displayApp.swift` – SwiftUI entry point that defines the `MenuBarExtra`.
- `ContentView.swift` – Popover interface showing the current desktop and quick actions.
- `SpaceObserver.swift` – Observable object that queries the current Space using private SkyLight APIs and publishes updates.

## License

MIT © AHpx
