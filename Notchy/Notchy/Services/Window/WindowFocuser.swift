import AppKit
import os.log

/// Focuses terminal windows, with optional yabai integration
@MainActor
struct WindowFocuser {
    static let shared = WindowFocuser()

    private static let logger = Logger(subsystem: "com.notchy.app", category: "WindowFocuser")

    private init() {}

    /// Focus the terminal window containing a Claude session
    /// - Parameter sessionPid: The PID of the Claude process
    /// - Returns: true if the window was focused successfully
    func focusTerminalWindow(forSessionPid sessionPid: Int) async -> Bool {
        let tree = ProcessTreeBuilder.shared.buildTree()

        guard let terminalPid = ProcessTreeBuilder.shared.findTerminalPid(forProcess: sessionPid, tree: tree) else {
            Self.logger.debug("No terminal PID found for session \(sessionPid)")
            return false
        }

        // Try yabai first (if available)
        if await YabaiController.shared.isAvailable() {
            let windows = WindowFinder.shared.findWindows(forPid: pid_t(terminalPid))
            for window in windows {
                if !WindowFinder.shared.isMinimized(window) {
                    if await YabaiController.shared.focusWindow(withPid: terminalPid) {
                        Self.logger.debug("Focused via yabai: PID \(terminalPid)")
                        return true
                    }
                }
            }
        }

        // Fall back to standard activation
        return activateApp(pid: pid_t(terminalPid))
    }

    /// Activate an app by PID using NSRunningApplication
    private func activateApp(pid: pid_t) -> Bool {
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            Self.logger.debug("No running app for PID \(pid)")
            return false
        }

        let activated = app.activate()

        // Also try to raise the frontmost window
        if activated {
            let windows = WindowFinder.shared.findWindows(forPid: pid)
            for window in windows {
                if !WindowFinder.shared.isMinimized(window) {
                    _ = WindowFinder.shared.raiseWindow(window)
                    break
                }
            }
        }

        Self.logger.debug("Activate app PID \(pid): \(activated)")
        return activated
    }
}
