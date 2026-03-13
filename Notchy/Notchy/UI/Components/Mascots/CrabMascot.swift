//
//  CrabMascot.swift
//  Notchy
//
//  Pixel art crab mascot drawing
//

import SwiftUI

enum CrabMascot {
    static func draw(in context: GraphicsContext, scale: CGFloat, color: Color, phase: Int) {
        // The original crab is 66 wide × 52 tall. Scale it down to fit 52×52 box.
        let hScale = scale * (52.0 / 66.0)
        let vScale = scale

        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
            Path { p in
                p.addRect(CGRect(x: x * hScale, y: y * vScale, width: w * hScale, height: h * vScale))
            }
        }

        // Antennae
        context.fill(rect(0, 13, 6, 13), with: .color(color))
        context.fill(rect(60, 13, 6, 13), with: .color(color))

        // Legs with walking animation
        let legPositions: [CGFloat] = [6, 18, 42, 54]
        let baseLegHeight: CGFloat = 13
        let offsets: [[CGFloat]] = [
            [3, -3, 3, -3],
            [0, 0, 0, 0],
            [-3, 3, -3, 3],
            [0, 0, 0, 0],
        ]
        let currentOffsets = offsets[phase % 4]
        for (i, xPos) in legPositions.enumerated() {
            let h = baseLegHeight + currentOffsets[i]
            context.fill(rect(xPos, 39, 6, h), with: .color(color))
        }

        // Body
        context.fill(rect(6, 0, 54, 39), with: .color(color))

        // Eyes
        context.fill(rect(12, 13, 6, 6.5), with: .color(.black))
        context.fill(rect(48, 13, 6, 6.5), with: .color(.black))
    }
}
