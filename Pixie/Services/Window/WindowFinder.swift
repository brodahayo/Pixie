import AppKit
import os.log

/// Discovers windows using the Accessibility API (AXUIElement)
struct WindowFinder: Sendable {
    static let shared = WindowFinder()

    private static let logger = Logger(subsystem: "com.notchy.app", category: "WindowFinder")

    private init() {}

    /// Find windows belonging to a specific PID
    func findWindows(forPid pid: pid_t) -> [AXUIElement] {
        let app = AXUIElementCreateApplication(pid)

        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success,
              let windows = windowsRef as? [AXUIElement] else {
            return []
        }

        return windows
    }

    /// Get the title of a window
    func windowTitle(_ window: AXUIElement) -> String? {
        var titleRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
        guard result == .success, let title = titleRef as? String else {
            return nil
        }
        return title
    }

    /// Check if a window is minimized
    func isMinimized(_ window: AXUIElement) -> Bool {
        var minimizedRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedRef)
        guard result == .success, let minimized = minimizedRef as? Bool else {
            return false
        }
        return minimized
    }

    /// Raise and focus a specific AXUIElement window
    func raiseWindow(_ window: AXUIElement) -> Bool {
        let raiseResult = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        return raiseResult == .success
    }

    /// Find the frontmost window for a PID
    func frontmostWindow(forPid pid: pid_t) -> AXUIElement? {
        let app = AXUIElementCreateApplication(pid)

        var windowRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &windowRef)

        guard result == .success else { return nil }
        // swiftlint:disable:next force_cast
        return (windowRef as! AXUIElement)
    }

    /// Find terminal windows that might contain a Claude session
    func findTerminalWindows(forSessionPid sessionPid: Int) -> [(pid: pid_t, window: AXUIElement)] {
        let tree = ProcessTreeBuilder.shared.buildTree()

        guard let terminalPid = ProcessTreeBuilder.shared.findTerminalPid(forProcess: sessionPid, tree: tree) else {
            Self.logger.debug("No terminal PID found for session PID \(sessionPid)")
            return []
        }

        let windows = findWindows(forPid: pid_t(terminalPid))
        return windows.map { (pid: pid_t(terminalPid), window: $0) }
    }
}
