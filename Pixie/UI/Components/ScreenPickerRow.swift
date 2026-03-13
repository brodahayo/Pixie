//
//  ScreenPickerRow.swift
//  Notchy
//
//  Display selection row for the settings menu
//

import SwiftUI

struct ScreenPickerRow: View {
    @ObservedObject private var selector = ScreenSelector.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header row
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selector.isPickerExpanded.toggle()
                    if selector.isPickerExpanded {
                        selector.refreshScreens()
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "display")
                        .font(.system(size: 11))
                        .foregroundColor(Color.accentColor)

                    Text("Display")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)

                    Spacer()

                    Text(currentDisplayName)
                        .font(.system(size: 10))
                        .foregroundColor(Color.secondary)

                    Image(systemName: selector.isPickerExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                        .foregroundColor(Color(white: 0.4))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded picker
            if selector.isPickerExpanded {
                VStack(spacing: 2) {
                    // Automatic option
                    optionRow(
                        label: "Automatic",
                        detail: "Prefers built-in display",
                        isSelected: selector.selectionMode == .automatic
                    ) {
                        selector.selectAutomatic()
                    }

                    // Available screens
                    ForEach(Array(selector.availableScreens.enumerated()), id: \.offset) { _, screen in
                        optionRow(
                            label: screen.localizedName,
                            detail: screenDetail(screen),
                            isSelected: selector.selectionMode == .specificScreen && selector.isSelected(screen)
                        ) {
                            selector.selectScreen(screen)
                        }
                    }
                }
                .padding(.leading, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var currentDisplayName: String {
        switch selector.selectionMode {
        case .automatic:
            return "Auto"
        case .specificScreen:
            return selector.selectedScreen?.localizedName ?? "Unknown"
        }
    }

    private func screenDetail(_ screen: NSScreen) -> String {
        let size = screen.frame.size
        return "\(Int(size.width))x\(Int(size.height))"
    }

    private func optionRow(label: String, detail: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? MascotColorPreset.current : Color(white: 0.4))

                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.white)

                Spacer()

                Text(detail)
                    .font(.system(size: 9))
                    .foregroundColor(Color.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.white.opacity(0.05) : Color.clear)
            .cornerRadius(4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
