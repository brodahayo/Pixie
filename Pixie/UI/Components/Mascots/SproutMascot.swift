//
//  SproutMascot.swift
//  Notchy
//
//  Pixel art Sprout mascot
//

import SwiftUI

enum SproutMascot {
    static func draw(in context: GraphicsContext, scale: CGFloat, color: Color, phase: Int) {
        // Sprout character spans ~6 cols (3-8) x 14 rows (0-13) in a 16x16 grid.
        // Scale up to fill 52x52 like the originals.
        // Use a larger pixel size and offset to center.
        let px: CGFloat = scale * 6.0  // each pixel ~6 units (vs 3.25 before)
        let offsetX: CGFloat = scale * 5.0  // center horizontally
        let offsetY: CGFloat = scale * 1.0

        func r(_ x: CGFloat, _ y: CGFloat) -> Path {
            Path { p in p.addRect(CGRect(
                x: x * px + offsetX,
                y: y * px + offsetY,
                width: px, height: px
            )) }
        }

        let leafGreen = Color(red: 0.55, green: 0.76, blue: 0.29)
        let leafLight = Color(red: 0.63, green: 0.83, blue: 0.37)
        let hl = color.opacity(0.6)

        // Leaf sway animation
        let leafOffsets: [CGFloat] = [-0.3, 0, 0.3, 0]
        let leafOff = leafOffsets[phase % 4]

        // Leaf
        context.fill(r(2 + leafOff, 0), with: .color(leafGreen))
        context.fill(r(3 + leafOff, 0), with: .color(leafLight))
        context.fill(r(2 + leafOff, 1), with: .color(leafGreen))

        // Stem
        context.fill(r(3, 1), with: .color(color))

        // Head row 2
        context.fill(r(1, 2), with: .color(color))
        context.fill(r(2, 2), with: .color(color))
        context.fill(r(3, 2), with: .color(color))
        context.fill(r(4, 2), with: .color(color))
        // Head rows 3-4
        for y: CGFloat in [3, 4] {
            for x: CGFloat in [0, 1, 2, 3, 4, 5] {
                context.fill(r(x, y), with: .color(color))
            }
        }
        // Eyes row 5
        context.fill(r(0, 5), with: .color(color))
        context.fill(r(1, 5), with: .color(.black))
        context.fill(r(2, 5), with: .color(color))
        context.fill(r(3, 5), with: .color(color))
        context.fill(r(4, 5), with: .color(.black))
        context.fill(r(5, 5), with: .color(color))
        // Body rows 6-7
        for y: CGFloat in [6, 7] {
            for x: CGFloat in [0, 1, 2, 3, 4, 5] {
                context.fill(r(x, y), with: .color(color))
            }
        }
        // Mouth row 8
        context.fill(r(0, 8), with: .color(color))
        context.fill(r(1, 8), with: .color(color))
        context.fill(r(2, 8), with: .color(hl))
        context.fill(r(3, 8), with: .color(hl))
        context.fill(r(4, 8), with: .color(color))
        context.fill(r(5, 8), with: .color(color))

        // Feet with walk animation
        let legOffsets: [CGFloat] = [0, -0.3, 0, 0.3]
        let legOff = legOffsets[phase % 4]
        context.fill(r(1 + legOff, 9), with: .color(color))
        context.fill(r(4 - legOff, 9), with: .color(color))
    }
}
