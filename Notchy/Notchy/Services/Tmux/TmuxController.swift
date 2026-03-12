//
//  TmuxController.swift
//  Notchy
//
//  Queries tmux for session/window/pane info and sends keys
//

import Foundation
import os.log

/// Parsed tmux pane information
struct TmuxPaneInfo: Sendable {
    let sessionName: String
    let windowIndex: String
    let paneIndex: String
    let panePid: Int
    let paneActive: Bool
    let windowActive: Bool

    var target: TmuxTarget {
        TmuxTarget(session: sessionName, window: windowIndex, pane: paneIndex)
    }
}

/// Controls tmux — queries sessions, windows, panes and sends keys
actor TmuxController {
    nonisolated(unsafe) static let shared = TmuxController()

    private static let logger = Logger(subsystem: "com.notchy.app", category: "TmuxController")

    private var tmuxPath: String?

    private init() {
        tmuxPath = TmuxPathFinder.shared.find()
    }

    /// Get the tmux binary path, refreshing if needed
    private func getTmuxPath() -> String? {
        if tmuxPath == nil {
            tmuxPath = TmuxPathFinder.shared.find()
        }
        return tmuxPath
    }

    /// List all panes across all sessions with their PIDs
    func listAllPanes() async -> [TmuxPaneInfo] {
        guard let tmux = getTmuxPath() else { return [] }

        // Format: session_name:window_index.pane_index:pane_pid:pane_active:window_active
        let format = "#{session_name}:#{window_index}.#{pane_index}:#{pane_pid}:#{pane_active}:#{window_active}"
        guard let output = await ProcessExecutor.shared.runOrNil(tmux, arguments: ["list-panes", "-a", "-F", format]) else {
            return []
        }

        var panes: [TmuxPaneInfo] = []
        for line in output.components(separatedBy: "\n") where !line.isEmpty {
            let parts = line.components(separatedBy: ":")
            guard parts.count >= 5 else { continue }

            // Parse session:window.pane
            let sessionName = parts[0]
            let windowPane = parts[1].components(separatedBy: ".")
            guard windowPane.count == 2 else { continue }
            let windowIndex = windowPane[0]
            let paneIndex = windowPane[1]

            guard let panePid = Int(parts[2]) else { continue }
            let paneActive = parts[3] == "1"
            let windowActive = parts[4] == "1"

            panes.append(TmuxPaneInfo(
                sessionName: sessionName,
                windowIndex: windowIndex,
                paneIndex: paneIndex,
                panePid: panePid,
                paneActive: paneActive,
                windowActive: windowActive
            ))
        }

        return panes
    }

    /// Send keys to a tmux target
    func sendKeys(_ keys: String, to target: TmuxTarget) async -> Bool {
        guard let tmux = getTmuxPath() else { return false }

        let result = await ProcessExecutor.shared.runWithResult(tmux, arguments: [
            "send-keys", "-t", target.targetString, keys, "Enter"
        ])

        switch result {
        case .success:
            Self.logger.debug("Sent keys to \(target.targetString, privacy: .public)")
            return true
        case .failure(let error):
            Self.logger.error("Failed to send keys to \(target.targetString, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// Check if a pane is the active pane in its window
    func isPaneActive(target: TmuxTarget) async -> Bool {
        let panes = await listAllPanes()
        return panes.first(where: {
            $0.sessionName == target.session &&
            $0.windowIndex == target.window &&
            $0.paneIndex == target.pane
        })?.paneActive ?? false
    }

    /// Check if tmux is available
    func isAvailable() -> Bool {
        getTmuxPath() != nil
    }
}
