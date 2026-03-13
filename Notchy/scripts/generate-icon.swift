#!/usr/bin/env swift
//
// generate-icon.swift
// Generates Pixie app icon PNGs — pixel art crab on dark background with neon glow
//

import AppKit
import CoreGraphics

// MARK: - Icon Design

func generateIcon(size: Int) -> NSImage {
    let s = CGFloat(size)

    // Create a bitmap rep at exact pixel dimensions (no Retina scaling)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: s, height: s)

    let image = NSImage(size: NSSize(width: s, height: s))
    image.addRepresentation(rep)

    NSGraphicsContext.saveGraphicsState()
    let gfxCtx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gfxCtx
    let ctx = gfxCtx.cgContext

    // --- Background: warm dark with subtle radial gradient ---
    let bgDark = NSColor(red: 0.078, green: 0.047, blue: 0.039, alpha: 1.0)
    let bgLight = NSColor(red: 0.137, green: 0.078, blue: 0.059, alpha: 1.0)

    // Rounded rect background (macOS icon mask)
    let cornerRadius = s * 0.22
    let bgPath = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: s, height: s), xRadius: cornerRadius, yRadius: cornerRadius)
    bgDark.setFill()
    bgPath.fill()

    // Subtle radial gradient overlay
    let gradientColors = [bgLight.cgColor, bgDark.cgColor] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: [0, 1])!
    ctx.saveGState()
    ctx.addPath(cgPath(from: bgPath))
    ctx.clip()
    ctx.drawRadialGradient(gradient,
                           startCenter: CGPoint(x: s * 0.5, y: s * 0.55),
                           startRadius: 0,
                           endCenter: CGPoint(x: s * 0.5, y: s * 0.55),
                           endRadius: s * 0.65,
                           options: .drawsAfterEndLocation)
    ctx.restoreGState()

    // --- Claude orange glow behind the crab ---
    let claudeOrange = NSColor(red: 0.85, green: 0.467, blue: 0.341, alpha: 1.0)
    let glowAlpha: CGFloat = 0.20
    let glowColor = NSColor(red: 0.85, green: 0.467, blue: 0.341, alpha: glowAlpha)

    ctx.saveGState()
    ctx.addPath(cgPath(from: bgPath))
    ctx.clip()
    let glowGradColors = [glowColor.cgColor, NSColor.clear.cgColor] as CFArray
    let glowGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: glowGradColors, locations: [0, 1])!
    ctx.drawRadialGradient(glowGrad,
                           startCenter: CGPoint(x: s * 0.5, y: s * 0.48),
                           startRadius: 0,
                           endCenter: CGPoint(x: s * 0.5, y: s * 0.48),
                           endRadius: s * 0.45,
                           options: .drawsAfterEndLocation)
    ctx.restoreGState()

    // --- Draw the pixel art crab ---
    // Crab original grid: 66 wide x 52 tall
    // We scale to fit nicely in the icon (about 60% of icon size)
    let crabScale = s * 0.55 / 52.0
    let crabWidth = 66.0 * crabScale * (52.0 / 66.0) // adjust for aspect ratio like MascotType does
    let crabHeight = 52.0 * crabScale
    let offsetX = (s - 66.0 * crabScale * (52.0 / 66.0)) / 2.0
    let offsetY = (s - crabHeight) / 2.0 - s * 0.02 // slightly above center

    let hScale = crabScale * (52.0 / 66.0)
    let vScale = crabScale

    func fillRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, color: NSColor) {
        let rect = NSRect(x: offsetX + x * hScale, y: offsetY + (52.0 * vScale - y * vScale - h * vScale), width: w * hScale, height: h * vScale)
        color.setFill()
        NSBezierPath(rect: rect).fill()
    }

    // Draw with a subtle outer glow effect (draw slightly larger, blurred copies)
    // We'll draw the crab body parts with the neon green color

    // Shadow/glow layer
    let shadow = NSShadow()
    shadow.shadowColor = claudeOrange.withAlphaComponent(0.6)
    shadow.shadowBlurRadius = s * 0.04
    shadow.shadowOffset = NSSize(width: 0, height: 0)
    shadow.set()

    let crabColor = claudeOrange

    // Antennae
    fillRect(0, 13, 6, 13, color: crabColor)
    fillRect(60, 13, 6, 13, color: crabColor)

    // Legs (static pose — phase 0 offsets: [3, -3, 3, -3])
    let legPositions: [CGFloat] = [6, 18, 42, 54]
    let legOffsets: [CGFloat] = [3, -3, 3, -3]
    for (i, xPos) in legPositions.enumerated() {
        let h: CGFloat = 13 + legOffsets[i]
        fillRect(xPos, 39, 6, h, color: crabColor)
    }

    // Body
    fillRect(6, 0, 54, 39, color: crabColor)

    // Reset shadow before drawing eyes
    let noShadow = NSShadow()
    noShadow.shadowColor = nil
    noShadow.set()

    // Eyes — dark cutouts
    let eyeColor = bgDark
    fillRect(12, 13, 6, 6.5, color: eyeColor)
    fillRect(48, 13, 6, 6.5, color: eyeColor)

    // --- Subtle border ring ---
    let borderColor = NSColor(red: 0.85, green: 0.467, blue: 0.341, alpha: 0.25)
    borderColor.setStroke()
    bgPath.lineWidth = s * 0.015
    bgPath.stroke()

    NSGraphicsContext.restoreGraphicsState()
    return image
}

// MARK: - Helpers

func cgPath(from bezierPath: NSBezierPath) -> CGPath {
    let path = CGMutablePath()
    let points = UnsafeMutablePointer<NSPoint>.allocate(capacity: 3)
    defer { points.deallocate() }

    for i in 0..<bezierPath.elementCount {
        let element = bezierPath.element(at: i, associatedPoints: points)
        switch element {
        case .moveTo:
            path.move(to: points[0])
        case .lineTo:
            path.addLine(to: points[0])
        case .curveTo, .cubicCurveTo:
            path.addCurve(to: points[2], control1: points[0], control2: points[1])
        case .closePath:
            path.closeSubpath()
        case .quadraticCurveTo:
            path.addQuadCurve(to: points[1], control: points[0])
        @unknown default:
            break
        }
    }
    return path
}

func savePNG(_ image: NSImage, to path: String) {
    guard let bitmap = image.representations.first as? NSBitmapImageRep,
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate PNG for \(path)")
        return
    }
    do {
        try png.write(to: URL(fileURLWithPath: path))
        print("Generated: \(path)")
    } catch {
        print("Error writing \(path): \(error)")
    }
}

// MARK: - Main

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

// macOS icon sizes: 16, 32, 128, 256, 512 (each at 1x and 2x)
let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for entry in sizes {
    let image = generateIcon(size: entry.pixels)
    let path = "\(outputDir)/\(entry.name).png"
    savePNG(image, to: path)
}

print("Done! Generated \(sizes.count) icon files.")
