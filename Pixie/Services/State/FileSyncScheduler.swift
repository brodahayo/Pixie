//
//  FileSyncScheduler.swift
//  Notchy
//
//  Handles debounced file sync scheduling for session JSONL files.
//

import Foundation
import os.log

/// Manages debounced file sync operations for session data
actor FileSyncScheduler {
    nonisolated static let logger = Logger(subsystem: "com.notchy.app", category: "FileSync")

    private var pendingSyncs: [String: Task<Void, Never>] = [:]
    private let debounceNs: UInt64 = 100_000_000

    typealias SyncHandler = @Sendable (String, String) async -> Void

    /// Schedule a debounced file sync for a session
    func schedule(sessionId: String, cwd: String, handler: @escaping SyncHandler) {
        cancel(sessionId: sessionId)

        pendingSyncs[sessionId] = Task { [debounceNs] in
            try? await Task.sleep(nanoseconds: debounceNs)
            guard !Task.isCancelled else { return }

            Self.logger.debug("Executing sync for session \(sessionId.prefix(8), privacy: .public)")
            await handler(sessionId, cwd)
        }
    }

    /// Cancel any pending sync for a session
    func cancel(sessionId: String) {
        if let existing = pendingSyncs.removeValue(forKey: sessionId) {
            existing.cancel()
            Self.logger.debug("Cancelled pending sync for session \(sessionId.prefix(8), privacy: .public)")
        }
    }

    /// Cancel all pending syncs
    func cancelAll() {
        for (_, task) in pendingSyncs {
            task.cancel()
        }
        pendingSyncs.removeAll()
    }

    /// Check if a sync is pending for a session
    func hasPendingSync(sessionId: String) -> Bool {
        pendingSyncs[sessionId] != nil
    }
}
