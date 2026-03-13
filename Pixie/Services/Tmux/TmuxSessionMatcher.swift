//
//  TmuxSessionMatcher.swift
//  Notchy
//
//  Matches Claude Code processes to their tmux panes
//

import Foundation
import os.log

/// Matches Claude Code processes to their tmux panes
struct TmuxSessionMatcher: Sendable {
    static let shared = TmuxSessionMatcher()

    private static let logger = Logger(subsystem: "com.notchy.app", category: "TmuxMatcher")

    private nonisolated init() {}

    /// Find the tmux pane containing a Claude process by PID
    /// Walks the process tree to find the tmux server, then matches to a pane
    func findPane(forClaudePid claudePid: Int) async -> TmuxPaneInfo? {
        let tree = ProcessTreeBuilder.shared.buildTree()

        // Verify the process is actually in tmux
        guard ProcessTreeBuilder.shared.isInTmux(pid: claudePid, tree: tree) else {
            return nil
        }

        // Get all tmux panes
        let panes = await TmuxController.shared.listAllPanes()
        guard !panes.isEmpty else {
            Self.logger.debug("No tmux panes found")
            return nil
        }

        // Strategy 1: Check if Claude PID is a descendant of any pane's shell PID
        for pane in panes {
            if ProcessTreeBuilder.shared.isDescendant(
                targetPid: claudePid,
                ofAncestor: pane.panePid,
                tree: tree
            ) {
                Self.logger.debug("Matched Claude PID \(claudePid) to pane \(pane.target.targetString, privacy: .public)")
                return pane
            }
        }

        // Strategy 2: Check if any pane PID is a descendant of Claude's process group
        // This handles cases where the process tree relationship is inverted
        let descendants = ProcessTreeBuilder.shared.findDescendants(of: claudePid, tree: tree)
        for pane in panes {
            if descendants.contains(pane.panePid) {
                Self.logger.debug("Matched (reverse) Claude PID \(claudePid) to pane \(pane.target.targetString, privacy: .public)")
                return pane
            }
        }

        // Strategy 3: Match by TTY
        if let claudeInfo = tree[claudePid],
           let claudeTty = claudeInfo.tty {
            for pane in panes {
                if let paneInfo = tree[pane.panePid],
                   let paneTty = paneInfo.tty,
                   paneTty == claudeTty {
                    Self.logger.debug("Matched by TTY Claude PID \(claudePid) to pane \(pane.target.targetString, privacy: .public)")
                    return pane
                }
            }
        }

        Self.logger.debug("Could not match Claude PID \(claudePid) to any tmux pane")
        return nil
    }
}
