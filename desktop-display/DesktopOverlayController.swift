//
//  DesktopOverlayController.swift
//  desktop-display
//
//  Presents a transient overlay indicating the active desktop.
//

import AppKit
import SwiftUI

final class DesktopOverlayController {
    static let shared = DesktopOverlayController()

    private var window: NSWindow?
    private var hostingController: NSHostingController<DesktopOverlayView>?
    private var dismissWorkItem: DispatchWorkItem?

    private init() {}

    func present(desktopIndex: Int) {
        DispatchQueue.main.async {
            self.showOverlay(desktopIndex: desktopIndex)
        }
    }

    private func showOverlay(desktopIndex: Int) {
        let rainbowEnabled = UserDefaults.standard.bool(forKey: "rainbowModeEnabled")
        let displayColor = rainbowEnabled ? DesktopPalette.color(for: desktopIndex) : .white
        let overlayView = DesktopOverlayView(desktopIndex: desktopIndex, accentColor: displayColor)

        if hostingController == nil {
            hostingController = NSHostingController(rootView: overlayView)
        } else {
            hostingController?.rootView = overlayView
        }

        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return
        }

        let desiredFrame = screen.frame

        if let window {
            window.contentViewController = hostingController
            window.setFrame(desiredFrame, display: true)
        } else {
            let overlayWindow = NSWindow(
                contentRect: desiredFrame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            overlayWindow.isReleasedWhenClosed = false
            overlayWindow.backgroundColor = .clear
            overlayWindow.isOpaque = false
            overlayWindow.hasShadow = false
            overlayWindow.level = .screenSaver
            overlayWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            overlayWindow.ignoresMouseEvents = true
            overlayWindow.contentViewController = hostingController
            self.window = overlayWindow
        }

        guard let window else { return }

        dismissWorkItem?.cancel()
        window.alphaValue = 0
        window.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().alphaValue = 1
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.hideOverlay()
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: workItem)
    }

    private func hideOverlay() {
        guard let window else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.window?.orderOut(nil)
        })
    }
}

private struct DesktopOverlayView: View {
    let desktopIndex: Int
    let accentColor: Color

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Desktop")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                Text("\(desktopIndex)")
                    .font(.system(size: 88, weight: .heavy, design: .monospaced))
                    .foregroundColor(accentColor)
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 36)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
        }
        .allowsHitTesting(false)
    }
}
