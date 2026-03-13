# Native macOS UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hacker terminal aesthetic with native macOS styling (system fonts, system colors, frosted glass materials) while preserving pixel art mascots and spinners.

**Architecture:** Full retheme in dependency order — create new color system first, then update components bottom-up (leaf components → picker rows → views), and finally delete the old `TerminalColors`. Each task produces a compilable state.

**Tech Stack:** SwiftUI, macOS 15.6+, SF Pro system fonts, SwiftUI materials (`.ultraThinMaterial`)

**Spec:** `docs/superpowers/specs/2026-03-13-native-macos-redesign.md`

---

## Chunk 1: Foundation + Components

### Task 1: Create PillButtonStyle and AppColors

**Files:**
- Create: `Notchy/UI/Components/PillButtonStyle.swift`
- Modify: `Notchy/UI/Components/TerminalColors.swift`

This task creates the new button style and adds a transitional compatibility layer to TerminalColors so subsequent tasks can migrate incrementally without breaking compilation.

- [ ] **Step 1: Create `PillButtonStyle.swift`**

```swift
//
//  PillButtonStyle.swift
//  Pixie
//
//  Pill-shaped button styles for approval actions
//

import SwiftUI

struct PillButtonStyle: ButtonStyle {
    let isPrimary: Bool
    let isSmall: Bool

    init(isPrimary: Bool, isSmall: Bool = false) {
        self.isPrimary = isPrimary
        self.isSmall = isSmall
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: isSmall ? 12 : 13, weight: .semibold))
            .padding(.horizontal, isSmall ? 16 : 22)
            .padding(.vertical, isSmall ? 5 : 7)
            .background(isPrimary ? Color.white : Color.white.opacity(0.1))
            .foregroundColor(isPrimary ? .black : Color.white.opacity(0.7))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Pixie.xcodeproj -scheme Pixie -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Notchy/UI/Components/PillButtonStyle.swift
git commit -m "feat: add PillButtonStyle for native approval buttons"
```

---

### Task 2: Update StatusIcons.swift

**Files:**
- Modify: `Notchy/UI/Components/StatusIcons.swift`

Replace TerminalColors default parameters with system colors. Keep all Canvas drawing code and pixel art unchanged.

- [ ] **Step 1: Update default color parameters**

Replace these exact lines:

- Line 15: `init(size: CGFloat = 12, color: Color = TerminalColors.green)` → `init(size: CGFloat = 12, color: Color = .green)`
- Line 78: `init(size: CGFloat = 12, color: Color = TerminalColors.amber)` → `init(size: CGFloat = 12, color: Color = .orange)`
- Line 120: `init(size: CGFloat = 12, color: Color = TerminalColors.cyan)` → `init(size: CGFloat = 12, color: Color = .blue)`
- Line 172: `.shadow(color: TerminalColors.glow, radius: 4)` → `.shadow(color: Color.white.opacity(0.15), radius: 4)`
- Line 190: `init(size: CGFloat = 12, color: Color = TerminalColors.dim)` → `init(size: CGFloat = 12, color: Color = .secondary)`

- [ ] **Step 2: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Pixie.xcodeproj -scheme Pixie -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Notchy/UI/Components/StatusIcons.swift
git commit -m "refactor: replace TerminalColors with system colors in StatusIcons"
```

---

### Task 3: Update NotchHeaderView.swift

**Files:**
- Modify: `Notchy/UI/Views/NotchHeaderView.swift`

Replace TerminalColors default parameters in indicator icon structs.

- [ ] **Step 1: Update color references**

- Line 15: `color: Color = TerminalColors.amber` → `color: Color = .orange`
- Line 45: `.shadow(color: TerminalColors.glow, radius: 4)` → `.shadow(color: Color.white.opacity(0.15), radius: 4)`
- Line 54: `color: Color = TerminalColors.green` → `color: Color = .green`
- Line 86: `.shadow(color: TerminalColors.glow, radius: 4)` → `.shadow(color: Color.white.opacity(0.15), radius: 4)`

- [ ] **Step 2: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Pixie.xcodeproj -scheme Pixie -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Notchy/UI/Views/NotchHeaderView.swift
git commit -m "refactor: replace TerminalColors with system colors in NotchHeaderView"
```

---

### Task 4: Update ActionButton.swift

**Files:**
- Modify: `Notchy/UI/Components/ActionButton.swift`

Switch from monospaced font to system font. ActionButton has no TerminalColors references but uses `.monospaced` design.

- [ ] **Step 1: Update font**

Change all `.font(.system(size: ..., design: .monospaced))` to `.font(.system(size: ...))` (remove `design: .monospaced`). Also change any `weight: .semibold, design: .monospaced` to just `weight: .semibold`.

- [ ] **Step 2: Build to verify**

- [ ] **Step 3: Commit**

```bash
git add Notchy/UI/Components/ActionButton.swift
git commit -m "refactor: switch ActionButton to system font"
```

---

### Task 5: Update MarkdownRenderer.swift

**Files:**
- Modify: `Notchy/UI/Components/MarkdownRenderer.swift`

Replace TerminalColors with system colors. Keep monospaced for code blocks and inline code only. Switch body/heading/quote text to system font.

- [ ] **Step 1: Update color references**

- Line 97: `TerminalColors.prompt` → `Color.accentColor` (code block text — actually keep this monospaced+accentColor is fine, but the color should be `.primary` since code is just white text on subtle bg)
  - Actually: code blocks should stay monospaced with `Color.primary` text
  - `text.foregroundColor = TerminalColors.prompt` → `text.foregroundColor = .primary` (UIColor/NSColor equivalent — check how AttributedString colors work in this file)
- Line 115: `TerminalColors.dim` → `Color.secondary`
- Line 118: `TerminalColors.dim` → `Color.secondary`
- Line 152: `TerminalColors.dim` → `Color.secondary`
- Line 168: `TerminalColors.dimmer` → `Color(white: 0.4)`
- Line 185: `TerminalColors.prompt` → `Color.primary` (inline code)
- Line 210: `TerminalColors.blue` → `Color.accentColor` (links)

- [ ] **Step 2: Update fonts — switch non-code text to system font**

Lines 116 and similar that set `.monospaced` for block quote prefixes should change to system font. Code blocks (line 96) and inline code (line 184) stay monospaced.

- [ ] **Step 3: Build to verify**

- [ ] **Step 4: Commit**

```bash
git add Notchy/UI/Components/MarkdownRenderer.swift
git commit -m "refactor: native colors and system font in MarkdownRenderer"
```

---

### Task 6: Update Picker Rows (MascotPickerRow, ScreenPickerRow, SoundPickerRow, SpinnerPickerRow)

**Files:**
- Modify: `Notchy/UI/Components/MascotPickerRow.swift`
- Modify: `Notchy/UI/Components/ScreenPickerRow.swift`
- Modify: `Notchy/UI/Components/SoundPickerRow.swift`
- Modify: `Notchy/UI/Components/SpinnerPickerRow.swift`

All four files follow the same pattern: replace TerminalColors refs and switch `.monospaced` to system font.

- [ ] **Step 1: In all four files, apply these replacements:**

**Color replacements (apply to all four):**
- `TerminalColors.cyan` → `Color.accentColor`
- `TerminalColors.dim` → `Color.secondary`
- `TerminalColors.dimmer` → `Color(white: 0.4)`
- `TerminalColors.background` → `Color.white.opacity(0.05)`
- `TerminalColors.backgroundHover` → `Color.white.opacity(0.08)`
- `TerminalColors.prompt` → `Color.accentColor`
- `TerminalColors.prompt.opacity(0.6)` → `Color.accentColor.opacity(0.6)`
- `TerminalColors.green` → `Color.green`

**Font replacements (apply to all four):**
- `.font(.system(size: N, design: .monospaced))` → `.font(.system(size: N))`
- `.font(.system(size: N, weight: W, design: .monospaced))` → `.font(.system(size: N, weight: W))`

**Exception:** In SpinnerPickerRow, the spinner preview label (line ~81 and ~116) should stay monospaced since it shows unicode spinner characters.

- [ ] **Step 2: Build to verify**

- [ ] **Step 3: Commit**

```bash
git add Notchy/UI/Components/MascotPickerRow.swift Notchy/UI/Components/ScreenPickerRow.swift Notchy/UI/Components/SoundPickerRow.swift Notchy/UI/Components/SpinnerPickerRow.swift
git commit -m "refactor: native colors and system font in all picker rows"
```

---

## Chunk 2: Main Views

### Task 7: Rewrite NotchMenuView.swift

**Files:**
- Modify: `Notchy/UI/Views/NotchMenuView.swift`

This is the biggest change — replace the entire custom panel layout with native SwiftUI `Form`.

- [ ] **Step 1: Rewrite the body**

Replace the current `body` with a native `Form` structure:

```swift
var body: some View {
    Form {
        Section("Display") {
            ScreenPickerRow()
            MascotPickerRow()
            SpinnerPickerRow()
            SoundPickerRow()
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
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                } else {
                    Button("Grant") { openAccessibilitySettings() }
                        .foregroundColor(.orange)
                        .font(.system(size: 12, weight: .medium))
                        .buttonStyle(.plain)
                }
            }

            HStack {
                Label("tmux", systemImage: "terminal")
                Spacer()
                Text(tmuxInstalled ? "Installed" : "Not Found")
                    .foregroundColor(tmuxInstalled ? .green : .secondary)
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
                    .foregroundColor(.green)
                    .font(.system(size: 12))
            }
        }

        Section("About") {
            Button {
                isCheckingForUpdates = true
                AppDelegate.shared?.updaterController?.updater.checkForUpdates()
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
```

- [ ] **Step 2: Delete the `settingsPanel` helper method** (no longer needed)

- [ ] **Step 3: Remove all old row computed properties** (`launchAtLoginRow`, `accessibilityRow`, `tmuxStatusRow`, `hookStatusRow`, `checkForUpdatesRow`, `githubRow`, `quitRow`) — they're now inline in the Form.

- [ ] **Step 4: Build to verify**

Note: If `.formStyle(.grouped)` produces too much padding in the compact notch, adjust with `.listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))` on sections.

- [ ] **Step 5: Commit**

```bash
git add Notchy/UI/Views/NotchMenuView.swift
git commit -m "refactor: rewrite NotchMenuView with native SwiftUI Form"
```

---

### Task 8: Update ClaudeInstancesView.swift

**Files:**
- Modify: `Notchy/UI/Views/ClaudeInstancesView.swift`

Replace TerminalColors with system colors, switch fonts, add capsule badges and pill buttons.

- [ ] **Step 1: Update color mappings**

Apply these replacements throughout the file:
- `TerminalColors.prompt` → `Color.green` (for LIVE/processing status)
- `TerminalColors.amber` → `Color.orange`
- `TerminalColors.red` → `Color.red`
- `TerminalColors.dim` → `Color.secondary`
- `TerminalColors.dimmer` → `Color(white: 0.4)`
- `TerminalColors.surface` → `Color.white.opacity(0.03)`
- `TerminalColors.border` → `Color.separator`
- `TerminalColors.green` → `Color.green`

- [ ] **Step 2: Update badge styling**

Replace the current badge text styling with capsule badges:

```swift
// Replace the badge computed property to return capsule-styled views
func badgeView(text: String, color: Color) -> some View {
    Text(text)
        .font(.system(size: 10, weight: .semibold))
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
}
```

- [ ] **Step 3: Replace ALLOW/DENY buttons with PillButtonStyle**

Replace the current custom-styled approval buttons:

```swift
Button("Allow") { /* existing action */ }
    .buttonStyle(PillButtonStyle(isPrimary: true, isSmall: true))
Button("Deny") { /* existing action */ }
    .buttonStyle(PillButtonStyle(isPrimary: false, isSmall: true))
```

- [ ] **Step 4: Update fonts**

- Session name: `.font(.system(size: 12, weight: .semibold))` (was monospaced bold)
- Meta text: `.font(.system(size: 11))` (was monospaced 10)
- Tool name: keep `.monospaced` (it's code content)
- Badge: `.font(.system(size: 10, weight: .semibold))`

- [ ] **Step 5: Build to verify**

- [ ] **Step 6: Commit**

```bash
git add Notchy/UI/Views/ClaudeInstancesView.swift
git commit -m "refactor: native colors, capsule badges, pill buttons in sessions view"
```

---

### Task 9: Update ChatView.swift

**Files:**
- Modify: `Notchy/UI/Views/ChatView.swift`

Replace TerminalColors, update bubble styling, switch non-code fonts to system, add pill buttons.

- [ ] **Step 1: Update color mappings**

- `TerminalColors.prompt` (user bubble bg) → `Color.accentColor`
- `TerminalColors.prompt.opacity(0.06)` → `Color.accentColor.opacity(0.1)`
- `TerminalColors.prompt.opacity(0.12)` → `Color.white` (for Allow button — now using PillButtonStyle)
- `TerminalColors.border` → `Color.separator`
- `TerminalColors.cyan` → `Color.blue`
- `TerminalColors.amber` → `Color.orange`
- `TerminalColors.green` → `Color.green`
- `TerminalColors.red` → `Color.red`
- `TerminalColors.dim` → `Color.secondary`
- `TerminalColors.dimmer` → `Color(white: 0.4)`
- `TerminalColors.background` → `Color.white.opacity(0.05)`

- [ ] **Step 2: Replace approval buttons with PillButtonStyle**

Replace the current custom ALLOW/DENY buttons in both the inline approval and bottom bar:

```swift
Button("Allow") { /* existing action */ }
    .buttonStyle(PillButtonStyle(isPrimary: true))
Button("Deny") { /* existing action */ }
    .buttonStyle(PillButtonStyle(isPrimary: false))
```

Remove the old custom button styling (`.background(TerminalColors.prompt.opacity(0.12))`, `.strokeBorder(...)`, etc.)

- [ ] **Step 3: Update fonts**

For non-code text, replace `.monospaced` with system:
- Message body: `.font(.system(size: 12))`
- Tool call labels: keep `.monospaced` for tool names
- Thinking blocks: `.font(.system(size: 11).italic())`
- Approval text: `.font(.system(size: 12, weight: .medium))`
- Input field: `.font(.system(size: 12))`
- Send button arrow: keep as-is

- [ ] **Step 4: Update send button color**

Change send button from `TerminalColors.prompt` to `Color.accentColor`.

- [ ] **Step 5: Build to verify**

- [ ] **Step 6: Commit**

```bash
git add Notchy/UI/Views/ChatView.swift
git commit -m "refactor: native colors, system font, pill buttons in ChatView"
```

---

### Task 10: Update ToolResultViews.swift

**Files:**
- Modify: `Notchy/UI/Views/ToolResultViews.swift`

This is the largest file (613 lines). Replace all TerminalColors refs. Keep monospaced for code content (which is most of this file — file paths, line numbers, bash output, diffs are all code).

- [ ] **Step 1: Apply color replacements**

- `TerminalColors.cyan` → `Color.blue`
- `TerminalColors.dim` → `Color.secondary`
- `TerminalColors.dimmer` → `Color(white: 0.4)`
- `TerminalColors.background` → `Color.white.opacity(0.05)`
- `TerminalColors.red` → `Color.red`
- `TerminalColors.green` → `Color.green`
- `TerminalColors.amber` → `Color.orange`
- `TerminalColors.blue` → `Color.blue`
- `TerminalColors.prompt` → `Color.green`
- `TerminalColors.magenta` → `Color.purple`
- `TerminalColors.surface` → `Color.white.opacity(0.03)`
- `TerminalColors.border` → `Color.separator`

- [ ] **Step 2: Update fonts**

Most content in ToolResultViews IS code content (file paths, line numbers, diffs, bash output) — keep `.monospaced` for these. Only change header labels like "File:", "Result:", "Status:" to system font:

```swift
// Headers/labels: system font
.font(.system(size: 11, weight: .medium))

// Code content: keep monospaced
.font(.system(size: 11, design: .monospaced))
```

- [ ] **Step 3: Build to verify**

- [ ] **Step 4: Commit**

```bash
git add Notchy/UI/Views/ToolResultViews.swift
git commit -m "refactor: native colors in ToolResultViews, keep monospaced for code"
```

---

## Chunk 3: NotchView + Cleanup

### Task 11: Update NotchView.swift

**Files:**
- Modify: `Notchy/UI/Views/NotchView.swift`

Replace all TerminalColors refs, add `.ultraThinMaterial` to opened content, replace custom segmented control with native Picker.

- [ ] **Step 1: Replace color references**

- Line 225: `.shadow(color: TerminalColors.glow, radius: 6)` → `.shadow(color: Color.white.opacity(0.15), radius: 6)`
- Line 239: `.shadow(color: TerminalColors.glow.opacity(breatheOpacity * 0.6), radius: 6)` → `.shadow(color: Color.white.opacity(breatheOpacity * 0.15), radius: 6)`
- Line 291: `color: TerminalColors.amber` → `color: .orange`
- Line 293: `.shadow(color: TerminalColors.amber.opacity(0.4), radius: 6)` → `.shadow(color: Color.orange.opacity(0.3), radius: 6)`
- Line 303: `.shadow(color: TerminalColors.glow, radius: 4)` → `.shadow(color: Color.white.opacity(0.15), radius: 4)`
- Line 312: `ReadyForInputIndicatorIcon(size: 14, color: TerminalColors.green)` → `ReadyForInputIndicatorIcon(size: 14, color: .green)`
- Line 313: `.shadow(color: TerminalColors.glow, radius: 4)` → `.shadow(color: Color.white.opacity(0.15), radius: 4)`
- Line 383: `.foregroundColor(TerminalColors.prompt)` → `.foregroundColor(.accentColor)`
- Line 400: `.strokeBorder(TerminalColors.border, lineWidth: 1)` → remove (native picker handles its own border)
- Line 414: `.foregroundColor(isActive ? TerminalColors.prompt : TerminalColors.dimmer)` → remove (replaced by native picker)
- Line 419: `.fill(isActive ? TerminalColors.backgroundHover : Color.clear)` → remove (replaced by native picker)

- [ ] **Step 2: Replace custom segmented control with native Picker**

Replace the custom `segmentButton` function and HStack segmented control with:

```swift
Picker("", selection: $selectedTab) {
    Text("Sessions").tag(0)
    Text("Config").tag(1)
}
.pickerStyle(.segmented)
.frame(width: 160)
```

Where `selectedTab` is a new `@State private var selectedTab = 0` that replaces the current tab switching logic. Wire it to call `viewModel.showInstances()` / `viewModel.showMenu()` via `.onChange(of: selectedTab)`.

- [ ] **Step 3: Add `.ultraThinMaterial` to opened content area**

In the opened state view, wrap the content area (below the header, above where the notch shell is) with:

```swift
.background(.ultraThinMaterial)
```

Keep the outer notch shell as `.black` to blend with the hardware notch.

- [ ] **Step 4: Update zzZ fonts — keep monospaced** (lines 341, 345, 349 — these stay as-is)

- [ ] **Step 5: Update back button font**

Line 382: `.font(.system(size: 12, weight: .bold, design: .monospaced))` → `.font(.system(size: 12, weight: .semibold))`

- [ ] **Step 6: Build to verify**

- [ ] **Step 7: Commit**

```bash
git add Notchy/UI/Views/NotchView.swift
git commit -m "refactor: native colors, material bg, segmented picker in NotchView"
```

---

### Task 12: Update ClosedStatePreview.swift

**Files:**
- Modify: `Notchy/UI/Views/ClosedStatePreview.swift`

Debug-only view. Just update the TerminalColors references.

- [ ] **Step 1: Replace color references**

- Line 111: `TerminalColors.prompt` → `Color.green`
- Line 119: `TerminalColors.green` → `Color.green`
- Line 153: `TerminalColors.prompt` → `Color.green`
- Line 166: `TerminalColors.green` → `Color.green`

- [ ] **Step 2: Build to verify**

- [ ] **Step 3: Commit**

```bash
git add Notchy/UI/Views/ClosedStatePreview.swift
git commit -m "refactor: replace TerminalColors in ClosedStatePreview"
```

---

### Task 13: Delete TerminalColors.swift

**Files:**
- Delete: `Notchy/UI/Components/TerminalColors.swift`

At this point, no file should reference `TerminalColors` anymore.

- [ ] **Step 1: Verify no remaining references**

Run: `grep -r "TerminalColors" Notchy/Notchy/ --include="*.swift"`
Expected: No output (zero matches)

If there are remaining references, fix them before proceeding.

- [ ] **Step 2: Delete the file**

```bash
rm Notchy/UI/Components/TerminalColors.swift
```

- [ ] **Step 3: Regenerate project and build**

```bash
xcodegen generate
xcodebuild -project Pixie.xcodeproj -scheme Pixie -configuration Debug build 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: delete TerminalColors.swift — migration to native colors complete"
```

---

### Task 14: Visual QA and Spacing Polish

**Files:**
- Potentially modify any file from Tasks 1-13

This is a manual testing task. Launch the app and verify every view looks correct.

- [ ] **Step 1: Build Release and launch**

```bash
xcodebuild -project Pixie.xcodeproj -scheme Pixie -configuration Release -derivedDataPath build build
open build/Build/Products/Release/Pixie.app
```

- [ ] **Step 2: Verify closed notch states**

Check: idle mascot, zzZ animation, processing spinner, approval indicator, done checkmark. All should look correct (pixel art unchanged, no neon green artifacts).

- [ ] **Step 3: Verify Sessions tab**

Check: session cards have consistent padding, capsule badges (LIVE green, WAIT orange, DONE gray), pill Allow/Deny buttons, progress bars use system colors, system font for labels, monospaced for tool names.

- [ ] **Step 4: Verify Config tab**

Check: native Form sections with proper headers, Toggle for Launch at Login, proper spacing (not too much padding from Form), status indicators with system green/orange.

If Form padding is too large for the notch, add `.listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))` to rows and `.scrollContentBackground(.hidden)` to Form.

- [ ] **Step 5: Verify Chat view**

Check: user bubbles with blue tint, assistant bubbles with subtle background, tool call rows with monospaced tool names, approval bar with pill buttons, input field and send button.

- [ ] **Step 6: Fix any spacing/alignment issues found**

Common fixes:
- Inconsistent padding → standardize to 12px horizontal, 8px vertical
- Text misalignment → ensure all rows use system font at consistent sizes
- Material background not showing → verify `.ultraThinMaterial` is applied after `.background(.black)` removal in content area

- [ ] **Step 7: Commit fixes**

```bash
git add -A
git commit -m "polish: spacing and alignment fixes from visual QA"
```

---

### Task 15: Rebuild Release DMG

**Files:**
- No code changes

- [ ] **Step 1: Run the release script**

```bash
bash scripts/create-release.sh
```
Expected: BUILD SUCCEEDED, DMG created at `release/Pixie-1.0.0.dmg`

- [ ] **Step 2: Install and verify**

```bash
rm -rf /Applications/Pixie.app
cp -R build/Build/Products/Release/Pixie.app /Applications/
xattr -cr /Applications/Pixie.app
open -a /Applications/Pixie.app
```

- [ ] **Step 3: Final visual check**

Verify the app launches, mascot shows in the notch, all tabs work, native styling is consistent throughout.
