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

    var body: some Scene {
        MenuBarExtra {
            ContentView(spaceObserver: spaceObserver)
        } label: {
            Text("\(spaceObserver.currentDesktopIndex)")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .frame(minWidth: 18)
                .accessibilityLabel("Current Desktop")
                .accessibilityValue("\(spaceObserver.currentDesktopIndex)")
        }
        .menuBarExtraStyle(.menu)
    }
}
