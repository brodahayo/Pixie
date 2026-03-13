//
//  MascotIcon.swift
//  Notchy
//
//  Drop-in replacement for ClaudeCrabIcon — renders the user's chosen mascot
//

import Combine
import SwiftUI

struct MascotIcon: View {
    let size: CGFloat
    var animate: Bool = false
    var colorOverride: Color? = nil

    @State private var phase: Int = 0

    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    private var mascotType: MascotType {
        MascotType(rawValue: Settings.mascotType) ?? .crab
    }

    private var resolvedColor: Color {
        colorOverride ?? MascotColorPreset.resolve(Settings.mascotColor)
    }

    var body: some View {
        Canvas { context, _ in
            mascotType.draw(in: context, size: size, color: resolvedColor, animationPhase: phase)
        }
        .frame(width: size, height: size)
        .onReceive(timer) { _ in
            if animate {
                phase = (phase + 1) % 4
            }
        }
    }
}
