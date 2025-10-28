//
//  DesktopOverlayController.swift
//  desktop-display
//
//  Presents a transient overlay indicating the active desktop.
//

import AppKit
import SwiftUI
import Combine

fileprivate final class DesktopOverlayState: ObservableObject {
    @Published var desktopIndex: Int = 1
    @Published var accentColor: Color = .white
}

final class DesktopOverlayController {
    static let shared = DesktopOverlayController()

    private var window: NSWindow?
    private var hostingController: NSHostingController<DesktopOverlayView>?
    private var dismissWorkItem: DispatchWorkItem?
    private let state = DesktopOverlayState()
    private var hideAnimationToken: UUID?

    private init() {}

    func present(desktopIndex: Int) {
        DispatchQueue.main.async {
            self.showOverlay(desktopIndex: desktopIndex)
        }
    }

    func dismiss() {
        DispatchQueue.main.async {
            self.dismissWorkItem?.cancel()
            self.hideOverlay(immediate: true)
        }
    }

    private func showOverlay(desktopIndex: Int) {
        let rainbowEnabled = UserDefaults.standard.bool(forKey: "rainbowModeEnabled")
        let displayColor = rainbowEnabled ? DesktopPalette.color(for: desktopIndex) : .white
        if hostingController == nil {
            state.desktopIndex = desktopIndex
            state.accentColor = displayColor
            hostingController = NSHostingController(rootView: DesktopOverlayView(state: state))
        } else {
            withAnimation(.easeInOut(duration: 0.15)) {
                state.desktopIndex = desktopIndex
                state.accentColor = displayColor
            }
        }

        guard let hostingController else { return }

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
        hideAnimationToken = nil

        let isAlreadyVisible = window.isVisible && window.alphaValue > 0.01

        if !isAlreadyVisible {
            window.alphaValue = 0
            window.orderFrontRegardless()

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                window.animator().alphaValue = 1
            }
        } else {
            window.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                window.animator().alphaValue = 1
            }
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.hideOverlay()
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: workItem)
    }

    private func hideOverlay(immediate: Bool = false) {
        guard let window else { return }

        if immediate {
            hideAnimationToken = nil
            window.alphaValue = 0
            window.orderOut(nil)
            return
        }

        let animationID = UUID()
        hideAnimationToken = animationID
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            guard let self, self.hideAnimationToken == animationID else { return }
            self.hideAnimationToken = nil
            self.window?.orderOut(nil)
        })
    }
}

private struct DesktopOverlayView: View {
    @ObservedObject var state: DesktopOverlayState

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Desktop")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                Text("\(state.desktopIndex)")
                    .font(.system(size: 88, weight: .heavy, design: .monospaced))
                    .foregroundColor(state.accentColor)
                    .animation(.easeInOut(duration: 0.15), value: state.desktopIndex)
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
