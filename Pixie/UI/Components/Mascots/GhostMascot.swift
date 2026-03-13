//
//  GhostMascot.swift
//  Notchy
//
//  Pixel art ghost mascot drawing
//

import SwiftUI

enum GhostMascot {
    static func draw(in context: GraphicsContext, scale: CGFloat, color: Color, phase: Int) {
        // Float animation - whole body shifts vertically
        let floatOffsets: [CGFloat] = [-2, 0, 2, 0]
        let yOff = floatOffsets[phase % 4]

        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
            Path { p in
                p.addRect(CGRect(x: x * scale, y: (y + yOff) * scale, width: w * scale, height: h * scale))
            }
        }

        // Dome / body
        context.fill(rect(10, 2, 32, 34), with: .color(color))
        context.fill(rect(6, 10, 4, 22), with: .color(color))
        context.fill(rect(42, 10, 4, 22), with: .color(color))

        // Wavy bottom (3 scallops)
        context.fill(rect(6, 36, 10, 8), with: .color(color))
        context.fill(rect(22, 36, 8, 8), with: .color(color))
        context.fill(rect(36, 36, 10, 8), with: .color(color))

        // Eyes (hollow ovals)
        context.fill(rect(14, 16, 8, 12), with: .color(.black))
        context.fill(rect(30, 16, 8, 12), with: .color(.black))
        // Inner eye highlight
        context.fill(rect(16, 18, 4, 4), with: .color(color))
        context.fill(rect(32, 18, 4, 4), with: .color(color))
    }
}
