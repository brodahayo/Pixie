//
//  MascotType.swift
//  Notchy
//
//  Mascot type and color preset enums
//

import SwiftUI

/// Available mascot characters
enum MascotType: String, CaseIterable, Sendable {
    case crab, robot, ghost, cat, skull, alien

    var displayName: String {
        switch self {
        case .crab: return "Crab"
        case .robot: return "Robot"
        case .ghost: return "Ghost"
        case .cat: return "Cat"
        case .skull: return "Skull"
        case .alien: return "Alien"
        }
    }

    /// Draw this mascot into a Canvas GraphicsContext
    func draw(in context: GraphicsContext, size: CGFloat, color: Color, animationPhase: Int) {
        let scale = size / 52.0
        switch self {
        case .crab: CrabMascot.draw(in: context, scale: scale, color: color, phase: animationPhase)
        case .robot: RobotMascot.draw(in: context, scale: scale, color: color, phase: animationPhase)
        case .ghost: GhostMascot.draw(in: context, scale: scale, color: color, phase: animationPhase)
        case .cat: CatMascot.draw(in: context, scale: scale, color: color, phase: animationPhase)
        case .skull: SkullMascot.draw(in: context, scale: scale, color: color, phase: animationPhase)
        case .alien: AlienMascot.draw(in: context, scale: scale, color: color, phase: animationPhase)
        }
    }
}

/// Color presets for mascots
enum MascotColorPreset: String, CaseIterable, Sendable {
    case claude, green, pink, blue, mono, ember

    var color: Color {
        switch self {
        case .claude: return Color(red: 0.0, green: 1.0, blue: 0.53)
        case .green: return Color(red: 0.39, green: 1.0, blue: 0.59)
        case .pink: return Color(red: 1.0, green: 0.59, blue: 0.78)
        case .blue: return Color(red: 0.39, green: 0.71, blue: 1.0)
        case .mono: return Color(red: 0.78, green: 0.78, blue: 0.86)
        case .ember: return Color(red: 1.0, green: 0.39, blue: 0.31)
        }
    }

    var displayName: String {
        switch self {
        case .claude: return "Hacker"
        case .green: return "Neon"
        case .pink: return "Pink"
        case .blue: return "Ice"
        case .mono: return "Mono"
        case .ember: return "Ember"
        }
    }

    /// Resolve a settings string to a Color
    static func resolve(_ key: String) -> Color {
        MascotColorPreset(rawValue: key)?.color
            ?? MascotColorPreset.claude.color
    }
}
