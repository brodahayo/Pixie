//
//  JSONLInterruptWatcher.swift
//  Notchy
//
//  Watches JSONL files for interrupt patterns in real-time
//  Uses file system events to detect interrupts faster than hook polling
//

import Foundation
import os.log

/// Logger for interrupt watcher
private let interruptLogger = Logger(subsystem: "com.notchy.app", category: "Interrupt")

protocol JSONLInterruptWatcherDelegate: AnyObject, Sendable {
    func didDetectInterrupt(sessionId: String)
}

/// Watches a session's JSONL file for interrupt patterns in real-time
class JSONLInterruptWatcher {
    private var fileHandle: FileHandle?
    private var source: DispatchSourceFileSystemObject?
    private var lastOffset: UInt64 = 0
    private let sessionId: String
    private let filePath: String
    private let queue = DispatchQueue(label: "com.notchy.interruptwatcher", qos: .userInteractive)

    weak var delegate: JSONLInterruptWatcherDelegate?

    private static let interruptContentPatterns = [
        "Interrupted by user",
        "interrupted by user",
        "user doesn't want to proceed",
        "[Request interrupted by user"
    ]

    init(sessionId: String, cwd: String) {
        self.sessionId = sessionId
        let projectDir = cwd.replacingOccurrences(of: "/", with: "-")
                            .replacingOccurrences(of: ".", with: "-")
        self.filePath = NSHomeDirectory() + "/.claude/projects/" + projectDir + "/" + sessionId + ".jsonl"
    }

    func start() {
        queue.async { [weak self] in
            self?.startWatching()
        }
    }

    private func startWatching() {
        stopInternal()

        guard FileManager.default.fileExists(atPath: filePath),
              let handle = FileHandle(forReadingAtPath: filePath) else {
            interruptLogger.warning("Failed to open file: \(self.filePath, privacy: .public)")
            return
        }

        fileHandle = handle

        do {
            lastOffset = try handle.seekToEnd()
        } catch {
            interruptLogger.error("Failed to seek to end: \(error.localizedDescription, privacy: .public)")
            return
        }

        let fd = handle.fileDescriptor
        let newSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend],
            queue: queue
        )

        newSource.setEventHandler { [weak self] in
            self?.checkForInterrupt()
        }

        newSource.setCancelHandler { [weak self] in
            try? self?.fileHandle?.close()
            self?.fileHandle = nil
        }

        source = newSource
        newSource.resume()

        interruptLogger.debug("Started watching: \(self.sessionId.prefix(8), privacy: .public)...")
    }

    private func checkForInterrupt() {
        guard let handle = fileHandle else { return }

        let currentSize: UInt64
        do {
            currentSize = try handle.seekToEnd()
        } catch {
            return
        }

        guard currentSize > lastOffset else { return }

        do {
            try handle.seek(toOffset: lastOffset)
        } catch {
            return
        }

        guard let newData = try? handle.readToEnd(),
              let newContent = String(data: newData, encoding: .utf8) else {
            return
        }

        lastOffset = currentSize

        let lines = newContent.components(separatedBy: "\n")
        for line in lines where !line.isEmpty {
            if isInterruptLine(line) {
                interruptLogger.info("Detected interrupt in session: \(self.sessionId.prefix(8), privacy: .public)")
                let sid = self.sessionId
                let del = self.delegate
                DispatchQueue.main.async {
                    del?.didDetectInterrupt(sessionId: sid)
                }
                return
            }
        }
    }

    private func isInterruptLine(_ line: String) -> Bool {
        if line.contains("\"type\":\"user\"") {
            if line.contains("[Request interrupted by user]") ||
               line.contains("[Request interrupted by user for tool use]") {
                return true
            }
        }

        if line.contains("\"tool_result\"") && line.contains("\"is_error\":true") {
            for pattern in Self.interruptContentPatterns {
                if line.contains(pattern) {
                    return true
                }
            }
        }

        if line.contains("\"interrupted\":true") {
            return true
        }

        return false
    }

    func stop() {
        queue.async { [weak self] in
            self?.stopInternal()
        }
    }

    private func stopInternal() {
        if source != nil {
            interruptLogger.debug("Stopped watching: \(self.sessionId.prefix(8), privacy: .public)...")
        }
        source?.cancel()
        source = nil
    }

    deinit {
        source?.cancel()
    }
}

// MARK: - Interrupt Watcher Manager

@MainActor
class InterruptWatcherManager {
    static let shared = InterruptWatcherManager()

    private var watchers: [String: JSONLInterruptWatcher] = [:]
    weak var delegate: JSONLInterruptWatcherDelegate?

    private init() {}

    func startWatching(sessionId: String, cwd: String) {
        guard watchers[sessionId] == nil else { return }

        let watcher = JSONLInterruptWatcher(sessionId: sessionId, cwd: cwd)
        watcher.delegate = delegate
        watcher.start()
        watchers[sessionId] = watcher
    }

    func stopWatching(sessionId: String) {
        watchers[sessionId]?.stop()
        watchers.removeValue(forKey: sessionId)
    }

    func stopAll() {
        for (_, watcher) in watchers {
            watcher.stop()
        }
        watchers.removeAll()
    }

    func isWatching(sessionId: String) -> Bool {
        watchers[sessionId] != nil
    }
}
