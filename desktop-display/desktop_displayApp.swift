//
//  desktop_displayApp.swift
//  desktop-display
//
//  Created by AHpx on 2025/10/28.
//

import SwiftUI

@main
struct desktop_displayApp: App {
    @StateObject private var spaceObserver = SpaceObserver()
    @AppStorage("rainbowModeEnabled") private var rainbowModeEnabled = false

    var body: some Scene {
        MenuBarExtra {
            ContentView(spaceObserver: spaceObserver)
        } label: {
            let indicatorColor = rainbowModeEnabled ? DesktopPalette.color(for: spaceObserver.currentDesktopIndex) : .primary
            Text("\(spaceObserver.currentDesktopIndex)")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .frame(minWidth: 18)
                .foregroundColor(indicatorColor)
                .accessibilityLabel("Current Desktop")
                .accessibilityValue("\(spaceObserver.currentDesktopIndex)")
        }
        .menuBarExtraStyle(.menu)
    }
}
