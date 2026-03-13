//
//  RobotMascot.swift
//  Notchy
//
//  Pixel art robot mascot drawing
//

import SwiftUI

enum RobotMascot {
    static func draw(in context: GraphicsContext, scale: CGFloat, color: Color, phase: Int) {
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
            Path { p in
                p.addRect(CGRect(x: x * scale, y: y * scale, width: w * scale, height: h * scale))
            }
        }

        // Antenna - bobs up/down
        let antennaOffsets: [CGFloat] = [-2, 0, 2, 0]
        let antennaY: CGFloat = antennaOffsets[phase % 4]
        context.fill(rect(23, antennaY, 6, 10), with: .color(color))

        // Head
        context.fill(rect(8, 10, 36, 22), with: .color(color))

        // Body
        context.fill(rect(14, 32, 24, 12), with: .color(color))

        // Arms
        context.fill(rect(6, 32, 8, 10), with: .color(color))
        context.fill(rect(38, 32, 8, 10), with: .color(color))

        // Legs
        context.fill(rect(16, 44, 8, 8), with: .color(color))
        context.fill(rect(28, 44, 8, 8), with: .color(color))

        // Eyes (square)
        context.fill(rect(14, 18, 8, 8), with: .color(.black))
        context.fill(rect(30, 18, 8, 8), with: .color(.black))

        // Mouth
        context.fill(rect(18, 28, 16, 3), with: .color(.black))
    }
}
