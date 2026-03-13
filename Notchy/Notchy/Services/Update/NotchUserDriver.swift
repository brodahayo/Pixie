//
//  NotchUserDriver.swift
//  Notchy
//
//  Sparkle update UI driver — drives update state via published properties
//  instead of traditional alert/window-based UI
//

import Combine
import Foundation
import os.log
import Sparkle

/// Update state observable by the settings menu
@MainActor
class UpdateState: ObservableObject {
    static let shared = UpdateState()

    @Published var isCheckingForUpdates = false
    @Published var updateAvailable = false
    @Published var updateVersion: String?
    @Published var downloadProgress: Double = 0
    @Published var isDownloading = false
    @Published var isInstalling = false
    @Published var statusText: String?
    @Published var errorMessage: String?

    private init() {}

    func reset() {
        isCheckingForUpdates = false
        updateAvailable = false
        updateVersion = nil
        downloadProgress = 0
        isDownloading = false
        isInstalling = false
        statusText = nil
        errorMessage = nil
    }
}

/// Custom Sparkle user driver that publishes state instead of showing native dialogs
final class NotchUserDriver: NSObject, SPUUserDriver, @unchecked Sendable {
    private static let logger = Logger(subsystem: "com.notchy.app", category: "Update")

    /// Whether the driver can handle interactive update checks
    var canCheckForUpdates: Bool { true }

    // MARK: - SPUUserDriver Protocol

    func show(_ request: SPUUpdatePermissionRequest, reply: @escaping (SUUpdatePermissionResponse) -> Void) {
        // Auto-allow update checks
        reply(SUUpdatePermissionResponse(automaticUpdateChecks: true, sendSystemProfile: false))
    }

    func showUserInitiatedUpdateCheck(cancellation: @escaping () -> Void) {
        Task { @MainActor in
            UpdateState.shared.isCheckingForUpdates = true
            UpdateState.shared.statusText = "Checking for updates..."
        }
    }

    func showUpdateFound(with appcastItem: SUAppcastItem, state: SPUUserUpdateState, reply: @escaping (SPUUserUpdateChoice) -> Void) {
        Task { @MainActor in
            UpdateState.shared.isCheckingForUpdates = false
            UpdateState.shared.updateAvailable = true
            UpdateState.shared.updateVersion = appcastItem.displayVersionString
            UpdateState.shared.statusText = "Update \(appcastItem.displayVersionString) available"
        }

        // Auto-install updates
        reply(.install)
    }

    func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {
        // No-op — release notes not shown in notch overlay
    }

    func showUpdateReleaseNotesFailedToDownloadWithError(_ error: Error) {
        // No-op — release notes not shown in notch overlay
    }

    func showUpdateNotFoundWithError(_ error: Error, acknowledgement: @escaping () -> Void) {
        Task { @MainActor in
            UpdateState.shared.isCheckingForUpdates = false
            UpdateState.shared.statusText = "Up to date"

            // Clear status after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if UpdateState.shared.statusText == "Up to date" {
                    UpdateState.shared.statusText = nil
                }
            }
        }
        acknowledgement()
    }

    func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
        Self.logger.error("Update error: \(error.localizedDescription, privacy: .public)")
        Task { @MainActor in
            UpdateState.shared.isCheckingForUpdates = false
            UpdateState.shared.isDownloading = false
            UpdateState.shared.errorMessage = error.localizedDescription
            UpdateState.shared.statusText = "Update failed"
        }
        acknowledgement()
    }

    func showDownloadInitiated(cancellation: @escaping () -> Void) {
        Task { @MainActor in
            UpdateState.shared.isDownloading = true
            UpdateState.shared.downloadProgress = 0
            UpdateState.shared.statusText = "Downloading..."
        }
    }

    func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {
        // No-op — we track progress via showDownloadDidReceiveData
    }

    func showDownloadDidReceiveData(ofLength length: UInt64) {
        // Progress updates are approximate since we don't always get content length
        Task { @MainActor in
            UpdateState.shared.downloadProgress = min(UpdateState.shared.downloadProgress + 0.1, 0.95)
        }
    }

    func showDownloadDidStartExtractingUpdate() {
        Task { @MainActor in
            UpdateState.shared.isDownloading = false
            UpdateState.shared.downloadProgress = 1.0
            UpdateState.shared.statusText = "Extracting..."
        }
    }

    func showExtractionReceivedProgress(_ progress: Double) {
        Task { @MainActor in
            UpdateState.shared.statusText = "Extracting... \(Int(progress * 100))%"
        }
    }

    func showReady(toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void) {
        Task { @MainActor in
            UpdateState.shared.isInstalling = true
            UpdateState.shared.statusText = "Ready to install"
        }
        // Auto-install and relaunch
        reply(.install)
    }

    func showInstallingUpdate(withApplicationTerminated applicationTerminated: Bool, retryTerminatingApplication: @escaping () -> Void) {
        Task { @MainActor in
            UpdateState.shared.isInstalling = true
            UpdateState.shared.statusText = "Installing..."
        }
    }

    func showUpdateInstalledAndRelaunched(_ relaunched: Bool, acknowledgement: @escaping () -> Void) {
        Task { @MainActor in
            UpdateState.shared.reset()
        }
        acknowledgement()
    }

    func showUpdateInFocus() {
        // No-op for notch overlay app
    }

    func dismissUpdateInstallation() {
        Task { @MainActor in
            UpdateState.shared.reset()
        }
    }
}
