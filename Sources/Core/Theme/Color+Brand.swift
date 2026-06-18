//
//  Color+Brand.swift
//  VexTrainer
//
//  Brand color tokens derived from the app icon. The actual color values live in
//  Assets.xcassets so they support light/dark variants automatically. Always use
//  these named accessors instead of hardcoding hex values anywhere in the app.
//

import SwiftUI

extension Color {

    // MARK: - Brand palette

    /// Deep navy from the icon background. Use for the app's primary surface in dark mode.
    static let vexNavy = Color("VexNavy")

    /// Primary brand accent — the orange `V` from the icon.
    /// Used for primary buttons, FABs, key calls-to-action, and the brand bar.
    static let vexOrange = Color("VexOrange")

    /// Secondary accent — the cyan `( )` from the icon.
    /// Used for links, informational text, secondary buttons, and selected states.
    static let vexCyan = Color("VexCyan")

    /// Success / progress — the green `;` from the icon.
    /// Used for "read" indicators, completed states, correct quiz answers, and progress bars.
    static let vexGreen = Color("VexGreen")
}
