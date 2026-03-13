//
//  WindowManager.swift
//  Notchy
//
//  Manages the notch window lifecycle.
//

import AppKit
import os.log

/// Logger for window management
private let logger = Logger(subsystem: "com.notchy.app", category: "Window")

@MainActor
final class WindowManager {
    private(set) var windowController: NotchWindowController?

    /// Set up or recreate the notch window.
    @discardableResult
    func setupNotchWindow() -> NotchWindowController? {
        // Use ScreenSelector for screen selection
        let screenSelector = ScreenSelector.shared
        screenSelector.refreshScreens()

        guard let screen = screenSelector.selectedScreen else {
            logger.warning("No screen found")
            return nil
        }

        // Tear down existing window if any
        if let existingController = windowController {
            existingController.window?.orderOut(nil)
            existingController.window?.close()
            windowController = nil
        }

        windowController = NotchWindowController(screen: screen)
        windowController?.showWindow(nil)

        return windowController
    }
}
