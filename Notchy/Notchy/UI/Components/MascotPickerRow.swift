//
//  MascotPickerRow.swift
//  Notchy
//
//  Mascot and color selection for settings menu
//

import SwiftUI

struct MascotPickerRow: View {
    @State private var isExpanded = false
    @State private var selectedType: String = Settings.mascotType
    @State private var selectedColor: String = Settings.mascotColor

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header row
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    MascotIcon(size: 12)
                        .frame(width: 16, height: 16)

                    Text("Mascot")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)

                    Spacer()

                    Text(currentMascotName)
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
                mascotGrid
                colorRow
            }
        }
    }

    private var currentMascotName: String {
        (MascotType(rawValue: selectedType) ?? .crab).displayName
    }

    // MARK: - Mascot Grid (3x2)

    private var mascotGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
        ], spacing: 6) {
            ForEach(MascotType.allCases, id: \.rawValue) { mascot in
                mascotThumbnail(mascot)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    private func mascotThumbnail(_ mascot: MascotType) -> some View {
        Button {
            selectedType = mascot.rawValue
            Settings.mascotType = mascot.rawValue
        } label: {
            VStack(spacing: 2) {
                Canvas { context, _ in
                    mascot.draw(
                        in: context,
                        size: 24,
                        color: MascotColorPreset.resolve(selectedColor),
                        animationPhase: 0
                    )
                }
                .frame(width: 24, height: 24)

                Text(mascot.displayName)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedType == mascot.rawValue
                        ? TerminalColors.backgroundHover
                        : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(selectedType == mascot.rawValue
                        ? TerminalColors.prompt.opacity(0.6)
                        : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Color Row

    private var colorRow: some View {
        HStack(spacing: 8) {
            ForEach(MascotColorPreset.allCases, id: \.rawValue) { preset in
                Button {
                    selectedColor = preset.rawValue
                    Settings.mascotColor = preset.rawValue
                } label: {
                    Circle()
                        .fill(preset.color)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: selectedColor == preset.rawValue ? 2 : 0)
                        )
                        .overlay(
                            selectedColor == preset.rawValue
                                ? Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black.opacity(0.6))
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
