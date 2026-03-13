//
//  SkullMascot.swift
//  Notchy
//
//  Pixel art skull mascot drawing
//

import SwiftUI

enum SkullMascot {
    static func draw(in context: GraphicsContext, scale: CGFloat, color: Color, phase: Int) {
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
            Path { p in
                p.addRect(CGRect(x: x * scale, y: y * scale, width: w * scale, height: h * scale))
            }
        }

        // Cranium
        context.fill(rect(8, 0, 36, 30), with: .color(color))
        context.fill(rect(4, 6, 4, 18), with: .color(color))
        context.fill(rect(44, 6, 4, 18), with: .color(color))

        // Jaw - opens/closes
        let jawOffsets: [CGFloat] = [0, 2, 4, 2]
        let jawGap = jawOffsets[phase % 4]
        context.fill(rect(12, 30 + jawGap, 28, 10), with: .color(color))

        // Teeth
        context.fill(rect(16, 30 + jawGap, 4, 4), with: .color(.black))
        context.fill(rect(24, 30 + jawGap, 4, 4), with: .color(.black))
        context.fill(rect(32, 30 + jawGap, 4, 4), with: .color(.black))

        // Eye sockets
        context.fill(rect(12, 10, 10, 12), with: .color(.black))
        context.fill(rect(30, 10, 10, 12), with: .color(.black))

        // Nose
        context.fill(rect(22, 22, 8, 6), with: .color(.black))
    }
}
