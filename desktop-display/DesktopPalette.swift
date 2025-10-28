//
//  DesktopPalette.swift
//  desktop-display
//
//  Provides a consistent color mapping for numbered desktop indicators.
//

import SwiftUI

enum DesktopPalette {
    private static let colors: [Color] = [
        .red,
        .green,
        .blue,
        .yellow,
        .orange,
        .indigo,
        .purple,
        .pink,
        .teal,
        .brown
    ]

    static func color(for index: Int) -> Color {
        guard index > 0 else { return .primary }
        return colors[(index - 1) % colors.count]
    }
}
