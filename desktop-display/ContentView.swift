//
//  ContentView.swift
//  desktop-display
//
//  Created by AHpx on 2025/10/28.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var spaceObserver: SpaceObserver
    @AppStorage("rainbowModeEnabled") private var rainbowModeEnabled = false

    private var desktopColor: Color {
        rainbowModeEnabled ? DesktopPalette.color(for: spaceObserver.currentDesktopIndex) : .primary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Desktop")
                .font(.headline)
            Text("\(spaceObserver.currentDesktopIndex)")
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(desktopColor)

            Divider()

            Toggle("Rainbow Mode", isOn: $rainbowModeEnabled)

            Button("Refresh Now") {
                spaceObserver.refresh()
            }

            Button("Quit Desktop Display") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(16)
        .frame(minWidth: 200)
    }
}

#Preview {
    ContentView(spaceObserver: SpaceObserver(initialSpaceIndex: 3, startMonitoring: false))
}
