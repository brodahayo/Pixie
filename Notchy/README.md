# Pixie

A macOS menu bar companion that lives in your MacBook's notch. Pixie monitors your [Claude Code](https://claude.ai/claude-code) sessions and surfaces approvals, status, and notifications — right where you're already looking.

![macOS](https://img.shields.io/badge/macOS-15.6+-black?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.0-00FF88?style=flat-square&logo=swift)
![License](https://img.shields.io/badge/License-Apache%202.0-blue?style=flat-square)

## Features

- **Live in the notch** — Pixie extends your MacBook's physical notch into a Dynamic Island-style status bar
- **Session dashboard** — See all active Claude Code sessions with live status badges (LIVE / WAIT / DONE), elapsed time, and last tool call
- **Instant approvals** — Approve or deny tool permissions directly from the notch without switching windows
- **Chat view** — Read and respond to Claude sessions inline
- **Notification sounds** — Hear when Claude needs your attention, even when you're in another app
- **Customizable mascots** — Choose from 6 pixel art characters (Crab, Robot, Ghost, Cat, Skull, Alien) with 6 color presets
- **12 spinner styles** — Tetris, Cosmic, Matrix Rain, Pixel art, and more
- **Hacker terminal aesthetic** — Neon green UI with monospaced fonts, glow effects, and grouped settings panels
- **Sleep mode** — After 45 seconds of idle, the mascot shows a cozy zzZ animation

## Install

### Download

1. Download the latest **Pixie.dmg** from [Releases](https://github.com/brodahayo/Pixie/releases)
2. Open the DMG and drag **Pixie** to your Applications folder
3. Launch Pixie

### First launch (important)

Since Pixie is not notarized with Apple (yet), macOS may block it on first launch:

1. **If you see "Pixie can't be opened"**: Go to **System Settings > Privacy & Security**, scroll down, and click **Open Anyway**
2. Or: Right-click the app > **Open** > click **Open** in the dialog
3. Grant **Accessibility** permission when prompted (required to detect terminal windows)

### Build from source

```bash
# Requirements: Xcode 16+, xcodegen
brew install xcodegen

git clone https://github.com/brodahayo/Pixie.git
cd Pixie
xcodegen generate
open Pixie.xcodeproj
# Build and run (Cmd+R)
```

## How it works

Pixie watches for Claude Code sessions via tmux and a lightweight hook system. When Claude is processing, needs approval, or finishes a task, Pixie updates the notch in real time.

| State | Left side | Right side |
|-------|-----------|------------|
| Idle | Mascot (breathing glow) | zzZ (after 45s) |
| Processing | Mascot (animated) | Spinner |
| Needs approval | Mascot | ? (amber glow) |
| Task complete | Mascot | Checkmark (green) |

Click the notch to expand it. Use the **Sessions** / **Config** tabs to switch between the session dashboard and settings.

## Settings

Open the notch and tap **Config**:

- **Display** — Screen, mascot character, mascot color, spinner style, notification sound
- **System** — Launch at login, accessibility status, tmux status, Claude hooks
- **About** — Check for updates, GitHub link, quit

## Requirements

- macOS 15.6 or later
- MacBook with a notch (M-series)
- [Claude Code](https://claude.ai/claude-code) CLI installed

## License

[Apache License 2.0](LICENSE.md)

## Credits

Built by [@brodahayo](https://github.com/brodahayo). Inspired by [Claude Island](https://github.com/farouqaldori/claude-island).
