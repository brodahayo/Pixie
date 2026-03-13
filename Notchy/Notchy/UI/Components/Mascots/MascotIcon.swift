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
    var jumping: Bool = false
    var colorOverride: Color? = nil

    @State private var phase: Int = 0
    @State private var jumpOffset: CGFloat = 0

    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

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
        .offset(y: jumpOffset)
        .onReceive(timer) { _ in
            if animate || jumping {
                phase = (phase + 1) % 4
            }
        }
        .onChange(of: jumping) { _, isJumping in
            if isJumping {
                startJumping()
            } else {
                withAnimation(.easeOut(duration: 0.15)) {
                    jumpOffset = 0
                }
            }
        }
        .onAppear {
            if jumping {
                startJumping()
            }
        }
    }

    private func startJumping() {
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            jumpOffset = -4
        }
    }
}
