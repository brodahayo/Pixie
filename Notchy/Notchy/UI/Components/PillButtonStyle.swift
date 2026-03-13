//
//  PillButtonStyle.swift
//  Pixie
//
//  Pill-shaped button styles for approval actions
//

import SwiftUI

struct PillButtonStyle: ButtonStyle {
    let isPrimary: Bool
    let isSmall: Bool

    init(isPrimary: Bool, isSmall: Bool = false) {
        self.isPrimary = isPrimary
        self.isSmall = isSmall
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: isSmall ? 12 : 13, weight: .semibold))
            .padding(.horizontal, isSmall ? 16 : 22)
            .padding(.vertical, isSmall ? 5 : 7)
            .background(isPrimary ? Color.white : Color.white.opacity(0.1))
            .foregroundColor(isPrimary ? .black : Color.white.opacity(0.7))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
