//
//  ClosedStatePreview.swift
//  Notchy
//
//  Visual test harness for closed-state notch indicators and all mascots
//

import SwiftUI

#if DEBUG

/// Preview all closed-state indicators and mascot characters
struct ClosedStatePreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Closed-State Indicator Test")
                    .font(.headline)
                    .foregroundColor(.white)

                // MARK: - All Mascots Grid

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Mascots (animated)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                        LazyVGrid(columns: [
                            GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(MascotType.allCases, id: \.rawValue) { mascot in
                                VStack(spacing: 6) {
                                    Canvas { context, _ in
                                        mascot.draw(
                                            in: context,
                                            size: 28,
                                            color: MascotColorPreset.claude.color,
                                            animationPhase: 0
                                        )
                                    }
                                    .frame(width: 28, height: 28)

                                    Text(mascot.displayName)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.05))
                                )
                            }
                        }
                    }
                    .padding(8)
                }

                // MARK: - Color Variants

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color Presets (crab)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                        HStack(spacing: 16) {
                            ForEach(MascotColorPreset.allCases, id: \.rawValue) { preset in
                                VStack(spacing: 4) {
                                    Canvas { context, _ in
                                        MascotType.crab.draw(
                                            in: context,
                                            size: 20,
                                            color: preset.color,
                                            animationPhase: 0
                                        )
                                    }
                                    .frame(width: 20, height: 20)

                                    Text(preset.displayName)
                                        .font(.system(size: 7, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                    }
                    .padding(8)
                }

                // MARK: - Simulated Closed States

                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Closed Notch States")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                        closedNotchSimulation(
                            label: "Processing",
                            leftContent: { MascotIcon(size: 14, animate: true) },
                            rightContent: { ProcessingSpinner() }
                        )

                        closedNotchSimulation(
                            label: "Permission Required",
                            leftContent: { MascotIcon(size: 14, animate: true) },
                            rightContent: {
                                PermissionIndicatorIcon(
                                    size: 14,
                                    color: TerminalColors.prompt
                                )
                            }
                        )

                        closedNotchSimulation(
                            label: "Ready for Input",
                            leftContent: { MascotIcon(size: 14) },
                            rightContent: { ReadyForInputIndicatorIcon(size: 14, color: TerminalColors.green) }
                        )

                        // Idle state with centered breathing mascot
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Idle (breathing)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))

                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.black)
                                    .frame(width: 252, height: 40)

                                MascotIcon(size: 14)
                                    .opacity(0.45)
                            }
                        }
                    }
                    .padding(8)
                }

                // MARK: - Status Icons

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Status Icons")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                        HStack(spacing: 24) {
                            VStack(spacing: 4) {
                                PermissionIndicatorIcon(
                                    size: 14,
                                    color: TerminalColors.prompt
                                )
                                Text("Permission")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            VStack(spacing: 4) {
                                ProcessingSpinner()
                                Text("Spinner")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            VStack(spacing: 4) {
                                ReadyForInputIndicatorIcon(size: 14, color: TerminalColors.green)
                                Text("Checkmark")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(8)
                }
            }
            .padding(20)
        }
        .background(Color(white: 0.1))
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func closedNotchSimulation<L: View, R: View>(
        label: String,
        @ViewBuilder leftContent: () -> L,
        @ViewBuilder rightContent: () -> R
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 0) {
                HStack(spacing: 4) {
                    leftContent()
                }
                .frame(width: 36, alignment: .center)

                RoundedRectangle(cornerRadius: 6)
                    .fill(.black)
                    .frame(width: 180, height: 32)

                HStack(spacing: 4) {
                    rightContent()
                }
                .frame(width: 36, alignment: .center)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.black)
            )
        }
    }
}

#Preview("Closed State Indicators") {
    ClosedStatePreview()
        .frame(width: 500, height: 700)
}

#endif
