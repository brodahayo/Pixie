//
//  SoundPickerRow.swift
//  Notchy
//
//  Sound selection row for the settings menu
//

import SwiftUI

struct SoundPickerRow: View {
    @ObservedObject private var selector = SoundSelector.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header row
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selector.isPickerExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 11))
                        .foregroundColor(TerminalColors.cyan)

                    Text("Sound")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)

                    Spacer()

                    Text(selector.selectedSound)
                        .font(.system(size: 10))
                        .foregroundColor(TerminalColors.dim)

                    Image(systemName: selector.isPickerExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .foregroundColor(TerminalColors.dimmer)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(TerminalColors.background)
                .cornerRadius(6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded picker
            if selector.isPickerExpanded {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(SoundSelector.availableSounds, id: \.self) { sound in
                            soundRow(sound)
                        }
                    }
                }
                .frame(maxHeight: selector.expandedPickerHeight)
                .padding(.leading, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func soundRow(_ sound: String) -> some View {
        Button {
            selector.selectSound(sound)
        } label: {
            HStack {
                Image(systemName: selector.selectedSound == sound ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 10))
                    .foregroundColor(selector.selectedSound == sound ? TerminalColors.green : TerminalColors.dimmer)

                Text(sound)
                    .font(.system(size: 10))
                    .foregroundColor(.white)

                Spacer()

                // Preview button
                Button {
                    selector.playPreview(sound)
                } label: {
                    Image(systemName: "play.circle")
                        .font(.system(size: 10))
                        .foregroundColor(TerminalColors.dim)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(selector.selectedSound == sound ? TerminalColors.background : Color.clear)
            .cornerRadius(4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
