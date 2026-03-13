//
//  AlienMascot.swift
//  Notchy
//
//  Pixel art alien mascot drawing
//

import SwiftUI

enum AlienMascot {
    static func draw(in context: GraphicsContext, scale: CGFloat, color: Color, phase: Int) {
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
            Path { p in
                p.addRect(CGRect(x: x * scale, y: y * scale, width: w * scale, height: h * scale))
            }
        }

        // Big head
        context.fill(rect(6, 0, 40, 28), with: .color(color))
        context.fill(rect(2, 6, 4, 16), with: .color(color))
        context.fill(rect(46, 6, 4, 16), with: .color(color))

        // Body
        context.fill(rect(16, 28, 20, 14), with: .color(color))

        // Legs
        context.fill(rect(12, 40, 8, 10), with: .color(color))
        context.fill(rect(32, 40, 8, 10), with: .color(color))

        // Eyes (large, black)
        context.fill(rect(10, 8, 14, 14), with: .color(.black))
        context.fill(rect(28, 8, 14, 14), with: .color(.black))

        // Pupils - blink animation (shrink vertically)
        let pupilHeights: [CGFloat] = [6, 4, 1, 4]
        let pupilH = pupilHeights[phase % 4]
        let pupilY: CGFloat = 12 + (6 - pupilH) / 2
        context.fill(rect(14, pupilY, 4, pupilH), with: .color(.white))
        context.fill(rect(34, pupilY, 4, pupilH), with: .color(.white))
    }
}
