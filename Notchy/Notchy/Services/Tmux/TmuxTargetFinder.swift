//
//  TmuxTargetFinder.swift
//  Notchy
//
//  Stub — full implementation in Task 15
//

import Foundation

actor TmuxTargetFinder {
    static let shared = TmuxTargetFinder()
    private init() {}

    /// Returns whether the tmux pane running the given Claude process is currently active.
    func isSessionPaneActive(claudePid: Int) async -> Bool {
        return false
    }
}
