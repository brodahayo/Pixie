//
//  ProcessingSpinner.swift
//  Notchy
//
//  Animated symbol spinner for processing state
//

import Combine
import SwiftUI

enum SpinnerStyle: String, CaseIterable, Sendable {
    case tetris
    case cosmic
    case dominos
    case electricity
    case matrixRain
    case pixelGrid
    case pixelBloom
    case pixelOrbit
    case pixelWeave
    case pixelPulse
    case pixelSpin
    case pixelDiamond

    var displayName: String {
        switch self {
        case .tetris: "Tetris"
        case .cosmic: "Cosmic"
        case .dominos: "Dominos"
        case .electricity: "Electricity"
        case .matrixRain: "Matrix Rain"
        case .pixelGrid: "Pixel Grid"
        case .pixelBloom: "Pixel Bloom"
        case .pixelOrbit: "Pixel Orbit"
        case .pixelWeave: "Pixel Weave"
        case .pixelPulse: "Pixel Pulse"
        case .pixelSpin: "Pixel Spin"
        case .pixelDiamond: "Pixel Diamond"
        }
    }

    var symbols: [String] {
        switch self {
        case .tetris: ["▖", "▘", "▝", "▗", "▚", "▞"]
        case .cosmic: ["✺", "✹", "✸", "✷", "✶", "✵", "✴", "✳"]
        case .dominos: ["🁣", "🁤", "🁥", "🁦", "🁧", "🁨"]
        case .electricity: ["⚡", "϶", "⚡", "϶", "↯", "϶"]
        case .matrixRain: ["ﾊ", "ﾐ", "ﾋ", "ｰ", "ｳ", "ｼ", "ﾅ", "ﾓ", "ﾆ", "ｻ"]
        case .pixelGrid: ["⣷", "⣯", "⣟", "⡿", "⢿", "⣻", "⣽", "⣾"]
        case .pixelBloom: ["▘", "▚", "▛", "█", "▜", "▞", "▗", "·"]
        case .pixelOrbit: ["▛", "▜", "▟", "▙"]
        case .pixelWeave: ["▚", "▞", "▚", "▞", "▒", "▓"]
        case .pixelPulse: ["░", "▒", "▓", "█", "▓", "▒", "░"]
        case .pixelSpin: ["◰", "◳", "◲", "◱"]
        case .pixelDiamond: ["◇", "◈", "◆", "◈", "◇", "·"]
        }
    }

    static func resolve(_ key: String) -> SpinnerStyle {
        SpinnerStyle(rawValue: key) ?? .tetris
    }
}

struct ProcessingSpinner: View {
    @State private var phase: Int = 0

    private var color: Color { MascotColorPreset.resolve(Settings.mascotColor) }
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    private var style: SpinnerStyle {
        SpinnerStyle.resolve(Settings.spinnerStyle)
    }

    var body: some View {
        let symbols = style.symbols
        Text(symbols[phase % symbols.count])
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(color)
            .frame(width: 14, alignment: .center)
            .onReceive(timer) { _ in
                phase = (phase + 1) % symbols.count
            }
    }
}
