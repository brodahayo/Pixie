//
//  SpinnerPickerRow.swift
//  Notchy
//
//  Spinner style selection for settings menu
//

import SwiftUI

struct SpinnerPickerRow: View {
    @State private var isExpanded = false
    @State private var selectedStyle: String = Settings.spinnerStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    ProcessingSpinner()
                        .frame(width: 16, height: 16)

                    Text("Spinner")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)

                    Spacer()

                    Text(currentStyleName)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(TerminalColors.dim)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(TerminalColors.dimmer)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(TerminalColors.background)
                .cornerRadius(6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                spinnerGrid
            }
        }
    }

    private var currentStyleName: String {
        SpinnerStyle.resolve(selectedStyle).displayName
    }

    // MARK: - Spinner Grid (3x4)

    private var spinnerGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
        ], spacing: 6) {
            ForEach(SpinnerStyle.allCases, id: \.rawValue) { style in
                spinnerThumbnail(style)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    private func spinnerThumbnail(_ style: SpinnerStyle) -> some View {
        Button {
            selectedStyle = style.rawValue
            Settings.spinnerStyle = style.rawValue
        } label: {
            VStack(spacing: 2) {
                SpinnerPreview(style: style)
                    .frame(width: 20, height: 20)

                Text(style.displayName)
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedStyle == style.rawValue
                        ? TerminalColors.backgroundHover
                        : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(selectedStyle == style.rawValue
                        ? TerminalColors.prompt.opacity(0.6)
                        : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Animated preview of a spinner style for the picker grid
private struct SpinnerPreview: View {
    let style: SpinnerStyle
    @State private var phase: Int = 0

    private var color: Color { MascotColorPreset.resolve(Settings.mascotColor) }
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var body: some View {
        let symbols = style.symbols
        Text(symbols[phase % symbols.count])
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .onReceive(timer) { _ in
                phase = (phase + 1) % symbols.count
            }
    }
}
