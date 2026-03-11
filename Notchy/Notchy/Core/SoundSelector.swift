//
//  SoundSelector.swift
//  Notchy
//
//  Manages sound selection state for the settings menu
//

import AppKit
import Combine
import Foundation

@MainActor
class SoundSelector: ObservableObject {
    static let shared = SoundSelector()

    // MARK: - Available Sounds

    static let availableSounds: [String] = [
        "Pop", "Ping", "Glass", "Basso", "Blow", "Bottle",
        "Frog", "Funk", "Hero", "Morse", "Purr", "Sosumi",
        "Submarine", "Tink"
    ]

    // MARK: - Published State

    @Published var isPickerExpanded: Bool = false
    @Published var selectedSound: String = Settings.notificationSound

    // MARK: - Constants

    /// Maximum number of sound options to show before scrolling
    private let maxVisibleOptions = 6

    /// Height per sound option row
    private let rowHeight: CGFloat = 32

    private init() {}

    // MARK: - Public API

    /// Select a sound, persist it, and play a preview
    func selectSound(_ sound: String) {
        selectedSound = sound
        Settings.notificationSound = sound
        playPreview(sound)
    }

    /// Play a preview of the given sound
    func playPreview(_ sound: String) {
        NSSound(named: sound)?.play()
    }

    /// Extra height needed when picker is expanded (capped for scrolling)
    var expandedPickerHeight: CGFloat {
        guard isPickerExpanded else { return 0 }
        let totalOptions = SoundSelector.availableSounds.count
        let visibleOptions = min(totalOptions, maxVisibleOptions)
        return CGFloat(visibleOptions) * rowHeight + 8 // +8 for padding
    }
}
