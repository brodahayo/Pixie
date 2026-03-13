//
//  TerminalColors.swift
//  Notchy
//
//  Hacker terminal color palette — neon green on black
//

import SwiftUI

struct TerminalColors {
    // Primary accent — neon green
    static let green = Color(red: 0.0, green: 1.0, blue: 0.53)       // #00FF88
    static let amber = Color(red: 1.0, green: 0.67, blue: 0.0)       // #FFAA00
    static let red = Color(red: 1.0, green: 0.27, blue: 0.27)        // #FF4444
    static let cyan = Color(red: 0.0, green: 0.67, blue: 1.0)        // #00AAFF
    static let blue = Color(red: 0.0, green: 0.67, blue: 1.0)        // #00AAFF (same as cyan)
    static let magenta = Color(red: 0.8, green: 0.4, blue: 0.8)      // keep for MCP tools

    // Text hierarchy
    static let dim = Color(white: 0.53)                                // #888888
    static let dimmer = Color(white: 0.33)                             // #555555

    // Accent (was Claude orange, now neon green)
    static let prompt = Color(red: 0.0, green: 1.0, blue: 0.53)      // #00FF88

    // Surfaces
    static let background = Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.025)  // subtle green tint
    static let backgroundHover = Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.06)

    // Borders and glow
    static let border = Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.13)       // #00FF8820
    static let glow = Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.4)          // for .shadow()
    static let surface = Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.03)      // panel gradient top
}
