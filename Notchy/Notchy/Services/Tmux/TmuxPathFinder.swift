//
//  TmuxPathFinder.swift
//  Notchy
//
//  Locates the tmux binary on the system
//

import Foundation
import os.log

struct TmuxPathFinder: Sendable {
    static let shared = TmuxPathFinder()

    private static let logger = Logger(subsystem: "com.notchy.app", category: "TmuxPath")

    private static let commonPaths = [
        "/opt/homebrew/bin/tmux",
        "/usr/local/bin/tmux",
        "/usr/bin/tmux"
    ]

    private nonisolated init() {}

    /// Find the tmux binary path, checking common locations first
    nonisolated func find() -> String? {
        // Check common paths first (fast)
        for path in Self.commonPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        // Fall back to `which tmux`
        if let output = ProcessExecutor.shared.runSyncOrNil("/usr/bin/which", arguments: ["tmux"]) {
            let path = output.trimmingCharacters(in: .whitespacesAndNewlines)
            if !path.isEmpty && FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        Self.logger.warning("tmux binary not found")
        return nil
    }
}
