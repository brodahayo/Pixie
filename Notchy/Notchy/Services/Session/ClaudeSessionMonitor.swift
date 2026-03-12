//
//  ClaudeSessionMonitor.swift
//  Notchy
//
//  STUB: Will be fully implemented in Task 13
//  Monitors active Claude Code sessions via hook events
//

import Combine
import SwiftUI

@MainActor
class ClaudeSessionMonitor: ObservableObject {
    // MARK: - Published State

    /// All known session instances
    @Published var instances: [SessionState] = []

    /// Sessions that have pending permission requests
    @Published var pendingInstances: [SessionState] = []

    // MARK: - Public API

    /// Start monitoring for Claude sessions
    func startMonitoring() {
        // STUB: Will connect to hook service in Task 13
    }

    /// Stop monitoring
    func stopMonitoring() {
        // STUB: Will disconnect from hook service in Task 13
    }
}
