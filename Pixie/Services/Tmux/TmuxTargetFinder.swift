//
//  TmuxTargetFinder.swift
//  Notchy
//
//  Finds and caches tmux targets for Claude sessions
//

import Foundation
import os.log

/// Finds and caches tmux targets for Claude sessions
actor TmuxTargetFinder {
    static let shared = TmuxTargetFinder()

    private static let logger = Logger(subsystem: "com.notchy.app", category: "TmuxTargetFinder")

    /// Cache of PID -> TmuxTarget for quick lookups
    private var targetCache: [Int: TmuxTarget] = [:]

    private init() {}

    /// Find the tmux target for a Claude process
    func findTarget(forClaudePid pid: Int) async -> TmuxTarget? {
        // Check cache first
        if let cached = targetCache[pid] {
            return cached
        }

        // Try to match via process tree
        guard let paneInfo = await TmuxSessionMatcher.shared.findPane(forClaudePid: pid) else {
            return nil
        }

        let target = paneInfo.target
        targetCache[pid] = target
        Self.logger.debug("Cached target \(target.targetString, privacy: .public) for PID \(pid)")
        return target
    }

    /// Returns whether the tmux pane running the given Claude process is currently active
    func isSessionPaneActive(claudePid: Int) async -> Bool {
        guard let target = await findTarget(forClaudePid: claudePid) else {
            return false
        }
        return await TmuxController.shared.isPaneActive(target: target)
    }

    /// Clear cached target for a PID (e.g., when session ends)
    func clearCache(forPid pid: Int) {
        targetCache.removeValue(forKey: pid)
    }

    /// Clear all cached targets
    func clearAllCaches() {
        targetCache.removeAll()
    }
}
