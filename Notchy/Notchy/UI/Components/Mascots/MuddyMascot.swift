//
//  MuddyMascot.swift
//  Notchy
//
//  Pixel art Muddy mascot
//

import SwiftUI

enum MuddyMascot {
    static func draw(in context: GraphicsContext, scale: CGFloat, color: Color, phase: Int) {
        // Muddy spans cols 1-12 (11 wide) x rows 1-13 (13 tall) in 16x16 grid.
        // Scale up to fill 52x52 like the originals.
        let px: CGFloat = scale * 4.5  // each pixel ~4.5 units
        let offsetX: CGFloat = scale * 1.0
        let offsetY: CGFloat = scale * 0.0

        func r(_ x: CGFloat, _ y: CGFloat) -> Path {
            Path { p in p.addRect(CGRect(
                x: x * px + offsetX,
                y: y * px + offsetY,
                width: px, height: px
            )) }
        }

        let hl = color.opacity(0.6)
        let dark = color.opacity(0.7)

        // Ear wiggle animation
        let earOffsets: [CGFloat] = [0, -0.3, 0, 0.3]
        let earOff = earOffsets[phase % 4]

        // Ears (rows 0-1)
        context.fill(r(2 + earOff, 0), with: .color(color))
        context.fill(r(3 + earOff, 0), with: .color(color))
        context.fill(r(8 - earOff, 0), with: .color(color))
        context.fill(r(9 - earOff, 0), with: .color(color))
        context.fill(r(2 + earOff, 1), with: .color(color))
        context.fill(r(3 + earOff, 1), with: .color(color))
        context.fill(r(8 - earOff, 1), with: .color(color))
        context.fill(r(9 - earOff, 1), with: .color(color))

        // Head rows 2-3
        for y: CGFloat in [2, 3] {
            for x: CGFloat in stride(from: 1, through: 10, by: 1) {
                context.fill(r(x, y), with: .color(color))
            }
        }

        // Eyes row 4
        context.fill(r(1, 4), with: .color(color))
        context.fill(r(2, 4), with: .color(color))
        context.fill(r(3, 4), with: .color(.black))
        context.fill(r(4, 4), with: .color(.black))
        context.fill(r(5, 4), with: .color(color))
        context.fill(r(6, 4), with: .color(color))
        context.fill(r(8, 4), with: .color(.black))
        context.fill(r(9, 4), with: .color(.black))
        context.fill(r(10, 4), with: .color(color))
        context.fill(r(11, 4), with: .color(color))

        // Body rows 5-6 with arms
        let armOffsets: [CGFloat] = [0, -0.3, 0, 0.3]
        let armOff = armOffsets[phase % 4]
        // Row 5
        for x: CGFloat in stride(from: 1, through: 10, by: 1) {
            context.fill(r(x, 5), with: .color(color))
        }
        // Row 6 with arms
        context.fill(r(0 + armOff, 6), with: .color(dark))
        for x: CGFloat in stride(from: 1, through: 10, by: 1) {
            context.fill(r(x, 6), with: .color(color))
        }
        context.fill(r(11 - armOff, 6), with: .color(dark))

        // Body rows 7-8
        for y: CGFloat in [7] {
            for x: CGFloat in stride(from: 1, through: 10, by: 1) {
                context.fill(r(x, y), with: .color(color))
            }
        }

        // Mouth row 8
        context.fill(r(1, 8), with: .color(color))
        context.fill(r(2, 8), with: .color(color))
        context.fill(r(3, 8), with: .color(color))
        context.fill(r(4, 8), with: .color(hl))
        context.fill(r(5, 8), with: .color(hl))
        context.fill(r(6, 8), with: .color(hl))
        context.fill(r(7, 8), with: .color(color))
        context.fill(r(8, 8), with: .color(color))
        context.fill(r(9, 8), with: .color(color))
        context.fill(r(10, 8), with: .color(color))

        // Body rows 9-10
        for y: CGFloat in [9, 10] {
            for x: CGFloat in stride(from: 1, through: 10, by: 1) {
                context.fill(r(x, y), with: .color(color))
            }
        }

        // Legs with walk animation
        let legOffsets: [CGFloat] = [0, 0.3, 0, -0.3]
        let legOff = legOffsets[phase % 4]
        // 3 legs
        context.fill(r(2 + legOff, 11), with: .color(color))
        context.fill(r(3 + legOff, 11), with: .color(color))
        context.fill(r(5, 11), with: .color(color))
        context.fill(r(6, 11), with: .color(color))
        context.fill(r(8 - legOff, 11), with: .color(color))
        context.fill(r(9 - legOff, 11), with: .color(color))
    }
}
