//
//  CatMascot.swift
//  Notchy
//
//  Pixel art cat mascot drawing
//

import SwiftUI

enum CatMascot {
    static func draw(in context: GraphicsContext, scale: CGFloat, color: Color, phase: Int) {
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
            Path { p in
                p.addRect(CGRect(x: x * scale, y: y * scale, width: w * scale, height: h * scale))
            }
        }

        // Ears (triangular - stacked rects)
        context.fill(rect(8, 0, 4, 6), with: .color(color))
        context.fill(rect(6, 6, 8, 4), with: .color(color))
        context.fill(rect(36, 0, 4, 6), with: .color(color))
        context.fill(rect(34, 6, 8, 4), with: .color(color))

        // Head + body
        context.fill(rect(6, 10, 36, 28), with: .color(color))

        // Tail - sways side to side
        let tailOffsets: [CGFloat] = [0, 2, 4, 2]
        let tailX: CGFloat = 42 + tailOffsets[phase % 4]
        context.fill(rect(tailX, 22, 6, 14), with: .color(color))
        context.fill(rect(tailX + 2, 18, 4, 6), with: .color(color))

        // Legs
        context.fill(rect(10, 38, 8, 10), with: .color(color))
        context.fill(rect(30, 38, 8, 10), with: .color(color))

        // Eyes
        context.fill(rect(14, 18, 6, 6), with: .color(.black))
        context.fill(rect(28, 18, 6, 6), with: .color(.black))

        // Nose
        context.fill(rect(22, 26, 4, 3), with: .color(.black))

        // Whiskers
        let whiskerColor = color.opacity(0.5)
        context.fill(rect(2, 24, 6, 2), with: .color(whiskerColor))
        context.fill(rect(2, 28, 6, 2), with: .color(whiskerColor))
        context.fill(rect(40, 24, 6, 2), with: .color(whiskerColor))
        context.fill(rect(40, 28, 6, 2), with: .color(whiskerColor))
    }
}
