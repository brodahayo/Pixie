//
//  AppDelegate.swift
//  Notchy
//
//  Application lifecycle — wires up all services on launch
//

@preconcurrency import ApplicationServices
import AppKit
import os.log
import Sparkle

private let logger = Logger(subsystem: "com.notchy.app", category: "AppDelegate")

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowManager: WindowManager?
    private var screenObserver: ScreenObserver?
    private var updaterController: SPUStandardUpdaterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single instance enforcement
        let runningApps = NSWorkspace.shared.runningApplications
        let myBundleId = Bundle.main.bundleIdentifier ?? ""
        if runningApps.filter({ $0.bundleIdentifier == myBundleId }).count > 1 {
            logger.warning("Another instance already running, terminating")
            NSApp.terminate(nil)
            return
        }

        logger.info("Notchy starting up")

        // 1. Check accessibility
        checkAccessibility()

        // 2. Install hooks
        HookInstaller.installIfNeeded()
        logger.info("Hooks installed")

        // 3. Start socket server
        HookSocketServer.shared.start(
            onEvent: { event in
                Task {
                    await SessionStore.shared.process(.hookReceived(event))
                }
            },
            onPermissionFailure: { sessionId, toolUseId in
                Task {
                    await SessionStore.shared.process(.permissionSocketFailed(sessionId: sessionId, toolUseId: toolUseId))
                }
            }
        )
        logger.info("Socket server started")

        // 4. Set up window
        windowManager = WindowManager()
        windowManager?.setupNotchWindow()
        logger.info("Notch window created")

        // 5. Observe screen changes
        screenObserver = ScreenObserver { [weak self] in
            ScreenSelector.shared.refreshScreens()
            self?.windowManager?.setupNotchWindow()
        }

        // 6. Initialize Sparkle updater
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        logger.info("Sparkle updater initialized")

        logger.info("Notchy startup complete")
    }

    func applicationWillTerminate(_ notification: Notification) {
        HookSocketServer.shared.stop()
        logger.info("Notchy shutting down")
    }

    // MARK: - Private

    private nonisolated func checkAccessibility() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            logger.info("Accessibility not granted — prompting user")
            let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            let options = [promptKey: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        } else {
            logger.info("Accessibility granted")
        }
    }
}
