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
    @State private var tmuxInstalled: Bool = TmuxPathFinder.shared.find() != nil
    @State private var hookStatus: String = "Installed"
    @State private var isAccessibilityGranted = AXIsProcessTrusted()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                settingsPanel(header: "DISPLAY") {
                    ScreenPickerRow()
                    MascotPickerRow()
                    SpinnerPickerRow()
                    SoundPickerRow()
                }

                settingsPanel(header: "SYSTEM") {
                    launchAtLoginRow
                    accessibilityRow
                    tmuxStatusRow
                    hookStatusRow
                }

                settingsPanel(header: "ABOUT") {
                    checkForUpdatesRow
                    githubRow
                    quitRow
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Panel Helper

    @ViewBuilder
    private func settingsPanel<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(header)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(TerminalColors.prompt)
                .tracking(1)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 6)

            VStack(alignment: .leading, spacing: 2) {
                content()
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [TerminalColors.surface, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(TerminalColors.border, lineWidth: 1)
        )
    }

    // MARK: - Launch at Login

    private var launchAtLoginRow: some View {
        Button {
            launchAtLogin.toggle()
            Settings.launchAtLogin = launchAtLogin
            updateLoginItem()
        } label: {
            HStack {
                Image(systemName: "power")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(TerminalColors.cyan)
                Text("Launch at Login")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                if launchAtLogin {
                    Text("ON")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(TerminalColors.prompt)
                        .cornerRadius(3)
                } else {
                    Text("OFF")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(TerminalColors.dimmer)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(TerminalColors.dimmer, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(TerminalColors.background)
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Accessibility

    private var accessibilityRow: some View {
        HStack {
            Image(systemName: "hand.raised")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(isAccessibilityGranted ? TerminalColors.green : TerminalColors.amber)
            Text("Accessibility")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white)
            Spacer()
            if isAccessibilityGranted {
                Text("Granted")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(TerminalColors.green)
            } else {
                Button("Grant") {
                    openAccessibilitySettings()
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(TerminalColors.amber)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(TerminalColors.background)
        .cornerRadius(6)
        .onAppear {
            isAccessibilityGranted = AXIsProcessTrusted()
        }
    }

    // MARK: - tmux Status

    private var tmuxStatusRow: some View {
        HStack {
            Image(systemName: "terminal")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(tmuxInstalled ? TerminalColors.green : TerminalColors.dim)
            Text("tmux")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white)
            Spacer()
            Text(tmuxInstalled ? "Installed" : "Not Found")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(tmuxInstalled ? TerminalColors.green : TerminalColors.dim)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(TerminalColors.background)
        .cornerRadius(6)
    }

    // MARK: - Hook Status

    private var hookStatusRow: some View {
        HStack {
            Image(systemName: "link")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(TerminalColors.cyan)
            Text("Claude Hooks")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white)
            Spacer()

            Button("Reinstall") {
                HookInstaller.installIfNeeded()
                hookStatus = "Reinstalled"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    hookStatus = "Installed"
                }
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(TerminalColors.cyan)
            .buttonStyle(.plain)

            Text(hookStatus)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(TerminalColors.green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(TerminalColors.background)
        .cornerRadius(6)
    }

    // MARK: - Check for Updates

    @State private var isCheckingForUpdates = false

    private var checkForUpdatesRow: some View {
        Button {
            isCheckingForUpdates = true
            AppDelegate.shared?.updaterController?.updater.checkForUpdates()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isCheckingForUpdates = false
            }
        } label: {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(TerminalColors.prompt)
                Text("Check for Updates")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                if isCheckingForUpdates {
                    Text("Checking...")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(TerminalColors.dim)
                } else {
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(TerminalColors.dimmer)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(TerminalColors.background)
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - GitHub Link

    private var githubRow: some View {
        Button {
            if let url = URL(string: "https://github.com/brodahayo/Pixie") {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack {
                Image(systemName: "link")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(TerminalColors.blue)
                Text("GitHub")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(TerminalColors.dimmer)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(TerminalColors.background)
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quit

    private var quitRow: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            HStack {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(TerminalColors.red)
                Text("Quit Pixie")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(TerminalColors.background)
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
