//
//  ToolApprovalHandler.swift
//  Notchy
//
//  Coordinates tool approval decisions through socket and tmux fallback paths
//

import Foundation
import os.log

/// Coordinates tool approval decisions through two paths:
/// 1. Socket-based (primary): responds via HookSocketServer
/// 2. tmux send-keys (fallback): sends keystrokes to the tmux pane
actor ToolApprovalHandler {
    nonisolated(unsafe) static let shared = ToolApprovalHandler()

    private static let logger = Logger(subsystem: "com.notchy.app", category: "ToolApproval")

    private init() {}

    /// Approve a tool use for a session
    /// - Parameters:
    ///   - sessionId: The session ID
    ///   - toolUseId: The tool use ID to approve
    ///   - pid: The Claude process PID (for tmux fallback)
    func approve(sessionId: String, toolUseId: String, pid: Int?) async {
        await respond(sessionId: sessionId, toolUseId: toolUseId, decision: "allow", pid: pid)
    }

    /// Deny a tool use for a session
    /// - Parameters:
    ///   - sessionId: The session ID
    ///   - toolUseId: The tool use ID to deny
    ///   - reason: Optional reason for denial
    ///   - pid: The Claude process PID (for tmux fallback)
    func deny(sessionId: String, toolUseId: String, reason: String? = nil, pid: Int?) async {
        await respond(sessionId: sessionId, toolUseId: toolUseId, decision: "deny", reason: reason, pid: pid)
    }

    /// Send a message to a Claude session via tmux or terminal fallback
    /// - Parameters:
    ///   - message: The message to send
    ///   - pid: The Claude process PID
    func sendMessage(_ message: String, toPid pid: Int) async -> Bool {
        // Path 1: Try tmux send-keys (for tmux sessions)
        if let target = await TmuxTargetFinder.shared.findTarget(forClaudePid: pid) {
            let escapedMessage = message
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "'", with: "\\'")

            let success = await TmuxController.shared.sendKeys(escapedMessage, to: target)
            if success { return true }
        }

        // Path 2: Fall back to AppleScript terminal input (for non-tmux sessions)
        Self.logger.info("Falling back to AppleScript input for PID \(pid)")
        return await TerminalInputSender.shared.sendMessage(message, toTerminalForPid: pid)
    }

    // MARK: - Private

    private func respond(
        sessionId: String,
        toolUseId: String,
        decision: String,
        reason: String? = nil,
        pid: Int?
    ) async {
        // Path 1: Try socket-based response (primary)
        if HookSocketServer.shared.hasPendingPermission(sessionId: sessionId) {
            Self.logger.info("Responding via socket: \(decision, privacy: .public) for \(sessionId.prefix(8), privacy: .public)")
            HookSocketServer.shared.respondToPermission(
                toolUseId: toolUseId,
                decision: decision,
                reason: reason
            )
            return
        }

        // Path 2: Fall back to tmux send-keys
        guard let pid = pid else {
            Self.logger.warning("No PID available for tmux fallback, cannot respond to \(sessionId.prefix(8), privacy: .public)")
            return
        }

        guard let target = await TmuxTargetFinder.shared.findTarget(forClaudePid: pid) else {
            Self.logger.warning("No tmux target for PID \(pid), cannot respond to \(sessionId.prefix(8), privacy: .public)")
            return
        }

        let key = decision == "allow" ? "y" : "n"
        Self.logger.info("Responding via tmux send-keys: \(key, privacy: .public) for \(sessionId.prefix(8), privacy: .public)")
        let success = await TmuxController.shared.sendKeys(key, to: target)

        if !success {
            Self.logger.error("Failed to send approval key via tmux for \(sessionId.prefix(8), privacy: .public)")
        }
    }
}
