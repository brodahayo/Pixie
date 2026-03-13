import Foundation
import os.log

/// Optional yabai window manager integration
actor YabaiController {
    nonisolated(unsafe) static let shared = YabaiController()

    private static let logger = Logger(subsystem: "com.notchy.app", category: "YabaiController")

    private static let commonPaths = [
        "/opt/homebrew/bin/yabai",
        "/usr/local/bin/yabai"
    ]

    private var yabaiPath: String?
    private var checkedAvailability = false

    private init() {}

    /// Check if yabai is installed and available
    func isAvailable() -> Bool {
        if !checkedAvailability {
            yabaiPath = findYabai()
            checkedAvailability = true
        }
        return yabaiPath != nil
    }

    /// Focus a window belonging to a specific PID
    func focusWindow(withPid pid: Int) async -> Bool {
        guard let yabai = yabaiPath else { return false }

        // Query yabai for windows matching the PID
        guard let output = await ProcessExecutor.shared.runOrNil(yabai, arguments: [
            "-m", "query", "--windows", "--space"
        ]) else { return false }

        // Parse JSON output to find window ID for this PID
        guard let data = output.data(using: .utf8),
              let windows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return false
        }

        guard let window = windows.first(where: { ($0["pid"] as? Int) == pid }),
              let windowId = window["id"] as? Int else {
            return false
        }

        // Focus the window
        let result = await ProcessExecutor.shared.runWithResult(yabai, arguments: [
            "-m", "window", "--focus", String(windowId)
        ])

        switch result {
        case .success:
            Self.logger.debug("Focused yabai window \(windowId) for PID \(pid)")
            return true
        case .failure:
            Self.logger.debug("Failed to focus yabai window for PID \(pid)")
            return false
        }
    }

    // MARK: - Private

    private func findYabai() -> String? {
        for path in Self.commonPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        if let output = ProcessExecutor.shared.runSyncOrNil("/usr/bin/which", arguments: ["yabai"]) {
            let path = output.trimmingCharacters(in: .whitespacesAndNewlines)
            if !path.isEmpty && FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        return nil
    }
}
