//
//  SessionPhaseHelpers.swift
//  Notchy
//
//  Helper functions for session phase display
//

import SwiftUI

struct SessionPhaseHelpers {
    /// Get color for session phase
    static func phaseColor(for phase: SessionPhase) -> Color {
        switch phase {
        case .waitingForApproval:
            return Color(red: 1.0, green: 0.75, blue: 0.0)   // amber
        case .waitingForInput:
            return Color(red: 0.0, green: 1.0, blue: 0.5)    // green
        case .processing:
            return Color(red: 0.0, green: 0.9, blue: 1.0)    // cyan
        case .compacting:
            return Color(red: 0.9, green: 0.0, blue: 0.9)    // magenta
        case .idle, .ended:
            return Color(white: 0.5)                           // dim
        }
    }

    /// Get description for session phase
    static func phaseDescription(for phase: SessionPhase) -> String {
        switch phase {
        case .waitingForApproval:
            return "Waiting for approval"
        case .waitingForInput:
            return "Ready for input"
        case .processing:
            return "Processing..."
        case .compacting:
            return "Compacting context..."
        case .idle:
            return "Idle"
        case .ended:
            return "Ended"
        }
    }

    /// Format time ago string
    static func timeAgo(_ date: Date, now: Date = Date()) -> String {
        let seconds = Int(now.timeIntervalSince(date))
        if seconds < 5 { return "now" }
        if seconds < 60 { return "\(seconds)s" }
        if seconds < 3600 { return "\(seconds / 60)m" }
        if seconds < 86400 { return "\(seconds / 3600)h" }
        return "\(seconds / 86400)d"
    }
}
