//
//  NotchMenuView.swift
//  Notchy
//
//  Settings panel with all app controls
//

import ServiceManagement
import Sparkle
import SwiftUI

struct NotchMenuView: View {
    @ObservedObject private var screenSelector = ScreenSelector.shared
    @ObservedObject private var soundSelector = SoundSelector.shared
    @State private var launchAtLogin = Settings.launchAtLogin
    @State private var muteNotifications = Settings.muteNotifications
    @State private var tmuxInstalled: Bool = TmuxPathFinder.shared.find() != nil
    @State private var hookStatus: String = "Installed"
    @State private var isAccessibilityGranted = AXIsProcessTrusted()
    @State private var isCheckingForUpdates = false

    var body: some View {
        Form {
            Section("Display") {
                ScreenPickerRow()
                MascotPickerRow()
                SpinnerPickerRow()
                SoundPickerRow()
                Toggle(isOn: $muteNotifications) {
                    Label("Mute Notifications", systemImage: "speaker.slash")
                }
                .onChange(of: muteNotifications) { _, newValue in
                    Settings.muteNotifications = newValue
                }
            }

            Section("System") {
                Toggle(isOn: $launchAtLogin) {
                    Label("Launch at Login", systemImage: "power")
                }
                .onChange(of: launchAtLogin) { _, newValue in
                    Settings.launchAtLogin = newValue
                    updateLoginItem()
                }

                HStack {
                    Label("Accessibility", systemImage: "hand.raised")
                    Spacer()
                    if isAccessibilityGranted {
                        Text("Granted")
                            .foregroundColor(MascotColorPreset.current)
                            .font(.system(size: 12))
                    } else {
                        Button("Grant") { openAccessibilitySettings() }
                            .foregroundColor(.orange)
                            .font(.system(size: 12, weight: .medium))
                            .buttonStyle(.plain)
                    }
                }
                .onAppear {
                    isAccessibilityGranted = AXIsProcessTrusted()
                }

                HStack {
                    Label("tmux", systemImage: "terminal")
                    Spacer()
                    Text(tmuxInstalled ? "Installed" : "Not Found")
                        .foregroundColor(tmuxInstalled ? MascotColorPreset.current : .secondary)
                        .font(.system(size: 12))
                }

                HStack {
                    Label("Claude Hooks", systemImage: "link")
                    Spacer()
                    Button("Reinstall") {
                        HookInstaller.installIfNeeded()
                        hookStatus = "Reinstalled"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            hookStatus = "Installed"
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentColor)
                    .buttonStyle(.plain)
                    Text(hookStatus)
                        .foregroundColor(MascotColorPreset.current)
                        .font(.system(size: 12))
                }
            }

            Section("About") {
                Button {
                    isCheckingForUpdates = true
                    AppDelegate.shared?.updater?.checkForUpdates()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        isCheckingForUpdates = false
                    }
                } label: {
                    HStack {
                        Label("Check for Updates", systemImage: "arrow.triangle.2.circlepath")
                        Spacer()
                        if isCheckingForUpdates {
                            Text("Checking...")
                                .foregroundColor(.secondary)
                                .font(.system(size: 11))
                        } else {
                            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                                .foregroundColor(.secondary)
                                .font(.system(size: 11))
                        }
                    }
                }
                .buttonStyle(.plain)

                Button {
                    if let url = URL(string: "https://github.com/brodahayo/Pixie") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    HStack {
                        Label("GitHub", systemImage: "link")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit Pixie", systemImage: "xmark.circle")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Actions

    private func updateLoginItem() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently fail — login item management may require elevated privileges
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
