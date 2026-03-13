//
//  TerminalInputSender.swift
//  Notchy
//
//  Sends input to terminal apps via CGEvent when tmux is unavailable
//

import AppKit
import Carbon.HIToolbox
import CoreGraphics
import Foundation
import os.log

/// Sends keyboard input to terminal applications using CGEvent
/// Used as fallback when Claude is not running in tmux
actor TerminalInputSender {
    nonisolated(unsafe) static let shared = TerminalInputSender()

    private static let logger = Logger(subsystem: "com.notchy.app", category: "TerminalInput")

    private init() {}

    /// Send a message to the terminal running a Claude process
    func sendMessage(_ message: String, toTerminalForPid claudePid: Int) async -> Bool {
        let tree = ProcessTreeBuilder.shared.buildTree()

        guard let terminalPid = ProcessTreeBuilder.shared.findTerminalPid(
            forProcess: claudePid, tree: tree
        ) else {
            Self.logger.warning("No terminal PID found for Claude PID \(claudePid)")
            return false
        }

        Self.logger.debug("Sending message to terminal PID \(terminalPid)")

        // Activate the terminal app first
        let activated = await MainActor.run {
            guard let app = NSRunningApplication(processIdentifier: pid_t(terminalPid)) else {
                return false
            }
            return app.activate()
        }

        if !activated {
            Self.logger.warning("Could not activate terminal PID \(terminalPid)")
        }

        // Small delay to let the terminal come to front
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // Type the message using CGEvent unicode input
        let success = Self.typeText(message, toPid: pid_t(terminalPid))
        guard success else {
            Self.logger.error("Failed to type message to terminal PID \(terminalPid)")
            return false
        }

        // Small delay before pressing Enter
        try? await Task.sleep(nanoseconds: 20_000_000) // 20ms

        // Press Enter to submit
        let enterSent = Self.pressEnter(toPid: pid_t(terminalPid))
        if !enterSent {
            Self.logger.error("Failed to send Enter key to terminal PID \(terminalPid)")
            return false
        }

        Self.logger.debug("Message sent to terminal PID \(terminalPid) via CGEvent")
        return true
    }

    /// Type a string using CGEvent unicode keyboard events
    private nonisolated static func typeText(_ text: String, toPid pid: pid_t) -> Bool {
        let source = CGEventSource(stateID: .combinedSessionState)

        // Send the text as unicode characters in chunks
        let utf16 = Array(text.utf16)
        let chunkSize = 20 // CGEvent supports up to ~20 unicode chars at a time

        for chunkStart in stride(from: 0, to: utf16.count, by: chunkSize) {
            let chunkEnd = min(chunkStart + chunkSize, utf16.count)
            var chunk = Array(utf16[chunkStart..<chunkEnd])

            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) else {
                return false
            }
            keyDown.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: &chunk)
            keyDown.postToPid(pid)

            guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
                return false
            }
            keyUp.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: &chunk)
            keyUp.postToPid(pid)
        }

        return true
    }

    /// Press the Enter/Return key
    private nonisolated static func pressEnter(toPid pid: pid_t) -> Bool {
        let source = CGEventSource(stateID: .combinedSessionState)
        let returnKeyCode: CGKeyCode = CGKeyCode(kVK_Return)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: returnKeyCode, keyDown: true) else {
            return false
        }
        keyDown.postToPid(pid)

        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: returnKeyCode, keyDown: false) else {
            return false
        }
        keyUp.postToPid(pid)

        return true
    }
}
