//
//  NotchMenuView.swift
//  Notchy
//
//  Settings panel with all app controls
//

import ServiceManagement
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
                sectionHeader("Display & Sound")
                ScreenPickerRow()
                SoundPickerRow()

                divider

                sectionHeader("General")
                launchAtLoginRow
                accessibilityRow
                tmuxStatusRow
                hookStatusRow

                divider

                sectionHeader("About")
                githubRow
                quitRow
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(TerminalColors.dim)
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.top, 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
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
                    .font(.system(size: 11))
                    .foregroundColor(TerminalColors.cyan)
                Text("Launch at Login")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: launchAtLogin ? "checkmark.square.fill" : "square")
                    .font(.system(size: 12))
                    .foregroundColor(launchAtLogin ? TerminalColors.green : TerminalColors.dimmer)
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
                .font(.system(size: 11))
                .foregroundColor(isAccessibilityGranted ? TerminalColors.green : TerminalColors.amber)
            Text("Accessibility")
                .font(.system(size: 11))
                .foregroundColor(.white)
            Spacer()
            if isAccessibilityGranted {
                Text("Granted")
                    .font(.system(size: 10))
                    .foregroundColor(TerminalColors.green)
            } else {
                Button("Grant") {
                    openAccessibilitySettings()
                }
                .font(.system(size: 10, weight: .medium))
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
                .font(.system(size: 11))
                .foregroundColor(tmuxInstalled ? TerminalColors.green : TerminalColors.red)
            Text("tmux")
                .font(.system(size: 11))
                .foregroundColor(.white)
            Spacer()
            Text(tmuxInstalled ? "Installed" : "Required")
                .font(.system(size: 10))
                .foregroundColor(tmuxInstalled ? TerminalColors.green : TerminalColors.red)
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
                .font(.system(size: 11))
                .foregroundColor(TerminalColors.cyan)
            Text("Claude Hooks")
                .font(.system(size: 11))
                .foregroundColor(.white)
            Spacer()

            Button("Reinstall") {
                HookInstaller.installIfNeeded()
                hookStatus = "Reinstalled"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    hookStatus = "Installed"
                }
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(TerminalColors.cyan)
            .buttonStyle(.plain)

            Text(hookStatus)
                .font(.system(size: 10))
                .foregroundColor(TerminalColors.green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(TerminalColors.background)
        .cornerRadius(6)
    }

    // MARK: - GitHub Link

    private var githubRow: some View {
        Button {
            if let url = URL(string: "https://github.com/farouqaldori/claude-island") {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack {
                Image(systemName: "link")
                    .font(.system(size: 11))
                    .foregroundColor(TerminalColors.blue)
                Text("GitHub")
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9))
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
                    .font(.system(size: 11))
                    .foregroundColor(TerminalColors.red)
                Text("Quit Notchy")
                    .font(.system(size: 11))
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
