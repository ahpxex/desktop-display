//
//  SpaceObserver.swift
//  desktop-display
//
//  Created to monitor the active macOS desktop (Space).
//

import AppKit
import Combine
import Foundation

@_silgen_name("CGSMainConnectionID")
private func CGSMainConnectionID() -> UInt32

@_silgen_name("CGSCopyManagedDisplaySpaces")
private func CGSCopyManagedDisplaySpaces(_ connection: UInt32) -> Unmanaged<CFArray>?

@_silgen_name("CGSCopyActiveMenuBarDisplayIdentifier")
private func CGSCopyActiveMenuBarDisplayIdentifier(_ connection: UInt32) -> Unmanaged<CFString>?

/// Reads the current desktop (Space) index for the active display by querying the private
/// SkyLight APIs that Mission Control uses internally.
enum SpaceDetector {
    static func currentSpaceIndex() -> Int? {
        let connection = CGSMainConnectionID()

        guard
            let managedSpaces = CGSCopyManagedDisplaySpaces(connection)?.takeRetainedValue() as? [[String: Any]]
        else {
            return nil
        }

        let activeDisplayIdentifier = CGSCopyActiveMenuBarDisplayIdentifier(connection)?.takeRetainedValue() as String?

        if let targetDisplay = activeDisplayIdentifier,
           let index = spaceIndex(for: targetDisplay, in: managedSpaces) {
            return index
        }

        // Fall back to the main display if no active menu bar display is reported.
        if let index = managedSpaces
            .compactMap({ displaySpace -> Int? in
                guard displaySpace["MainID"] as? Bool == true ||
                        displaySpace["MainDisplay"] as? Bool == true ||
                        displaySpace["kCGDisplayIsMain"] as? Bool == true else {
                    return nil
                }
                return currentIndex(in: displaySpace)
            })
            .first {
            return index
        }

        // As a last resort, return the first display's current space index.
        for displaySpace in managedSpaces {
            if let index = currentIndex(in: displaySpace) {
                return index
            }
        }

        return nil
    }

    private static func spaceIndex(for displayIdentifier: String, in managedSpaces: [[String: Any]]) -> Int? {
        for displaySpace in managedSpaces {
            guard let identifier = displaySpace["Display Identifier"] as? String else { continue }
            if identifier == displayIdentifier {
                return currentIndex(in: displaySpace)
            }
        }
        return nil
    }

    private static func currentIndex(in displaySpace: [String: Any]) -> Int? {
        guard
            let spaces = displaySpace["Spaces"] as? [[String: Any]],
            let currentSpaceInfo = displaySpace["Current Space"] as? [String: Any],
            let currentManagedID = intValue(from: currentSpaceInfo["ManagedSpaceID"] ?? currentSpaceInfo["Managed Space ID"])
        else {
            return nil
        }

        for (offset, space) in spaces.enumerated() {
            let spaceManagedID = intValue(from: space["ManagedSpaceID"] ?? space["Managed Space ID"])
            if spaceManagedID == currentManagedID {
                return offset + 1 // Spaces are 1-indexed for user expectations.
            }
        }

        return nil
    }

    private static func intValue(from value: Any?) -> Int? {
        switch value {
        case let number as NSNumber:
            return number.intValue
        case let string as String:
            return Int(string)
        case let intValue as Int:
            return intValue
        default:
            return nil
        }
    }
}

/// Publishes changes to the current desktop index and keeps the menu bar label in sync.
final class SpaceObserver: ObservableObject {
    @Published private(set) var currentDesktopIndex: Int

    private var spaceChangeObserver: NSObjectProtocol?
    private var pollTimer: Timer?

    init(initialSpaceIndex: Int = 1, startMonitoring: Bool = true) {
        currentDesktopIndex = initialSpaceIndex

        guard startMonitoring else {
            return
        }

        updateCurrentSpace()
        spaceChangeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: NSWorkspace.shared,
            queue: .main
        ) { [weak self] _ in
            self?.updateCurrentSpace()
        }

        // Fallback polling keeps the state fresh if the notification misses an event.
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.updateCurrentSpace()
        }
        if let pollTimer {
            RunLoop.main.add(pollTimer, forMode: .common)
        }
    }

    deinit {
        if let spaceChangeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(spaceChangeObserver)
        }
        pollTimer?.invalidate()
    }

    /// Exposed for manual refresh (e.g., from the menu UI).
    func refresh() {
        updateCurrentSpace()
    }

    private func updateCurrentSpace() {
        guard let index = SpaceDetector.currentSpaceIndex() else { return }
        if index != currentDesktopIndex {
            currentDesktopIndex = index
            if UserDefaults.standard.bool(forKey: "overlayEnabled") {
                DesktopOverlayController.shared.present(desktopIndex: index)
            } else {
                DesktopOverlayController.shared.dismiss()
            }
        }
    }
}
