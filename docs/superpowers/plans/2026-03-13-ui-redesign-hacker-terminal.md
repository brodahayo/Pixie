# Hacker Terminal UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign Notchy's UI from warm orange terminal aesthetic to neon green hacker terminal, with restructured navigation (segmented control), dashboard session panels, and grouped settings panels — differentiating it from the original Claude Island project.

**Architecture:** Bottom-up approach — start with the color foundation (TerminalColors), then restyle components, then restructure layouts. Each task produces a buildable, testable change. The notch shape and all core logic remain untouched.

**Tech Stack:** SwiftUI, Canvas (mascot/icon drawing), macOS AppKit (NSPanel overlay)

**Spec:** `docs/superpowers/specs/2026-03-13-ui-redesign-hacker-terminal-design.md`

---

## File Structure

### Modified files

| File | Responsibility | Change |
|---|---|---|
| `Notchy/Notchy/UI/Components/TerminalColors.swift` | Color palette | Full rewrite — neon green palette |
| `Notchy/Notchy/UI/Components/Mascots/MascotType.swift` | Mascot color presets | Update `claude` preset to neon green |
| `Notchy/Notchy/UI/Components/ProcessingSpinner.swift` | Loading spinner | Change color to `TerminalColors.prompt` |
| `Notchy/Notchy/UI/Components/StatusIcons.swift` | Pixel art status icons | Use TerminalColors refs, no hardcoded colors |
| `Notchy/Notchy/UI/Components/ActionButton.swift` | Reusable button | Monospaced font, neon styling |
| `Notchy/Notchy/UI/Components/MascotPickerRow.swift` | Mascot settings picker | Green accents, monospaced |
| `Notchy/Notchy/UI/Components/SpinnerPickerRow.swift` | Spinner settings picker | Green accents, monospaced |
| `Notchy/Notchy/UI/Components/SoundPickerRow.swift` | Sound settings picker | Green accents, monospaced |
| `Notchy/Notchy/UI/Components/ScreenPickerRow.swift` | Screen settings picker | Green accents, monospaced |
| `Notchy/Notchy/UI/Views/NotchView.swift` | Main notch container | Idle mascot left-aligned, glow effects |
| `Notchy/Notchy/UI/Views/NotchHeaderView.swift` | Header + status icons | Segmented control, glow on icons |
| `Notchy/Notchy/UI/Views/NotchMenuView.swift` | Settings panel | Grouped panels layout |
| `Notchy/Notchy/UI/Views/ClaudeInstancesView.swift` | Session list | Dashboard panels with badges |
| `Notchy/Notchy/UI/Views/ChatView.swift` | Conversation view | Green-tinted bubbles, neon buttons |
| `Notchy/Notchy/UI/Views/ToolResultViews.swift` | Tool result displays | Monospaced fonts, green colors |
| `Notchy/Notchy/UI/Components/MarkdownRenderer.swift` | Rich text rendering | Green code blocks |
| `Notchy/Notchy/UI/Views/ClosedStatePreview.swift` | Debug preview | Match new styling |

---

## Chunk 1: Foundation — Colors, Typography, Component Restyling

### Task 1: Rewrite TerminalColors

**Files:**
- Modify: `Notchy/Notchy/UI/Components/TerminalColors.swift` (lines 1-23, full rewrite)

- [ ] **Step 1: Rewrite TerminalColors.swift with new neon palette**

```swift
//
//  TerminalColors.swift
//  Notchy
//
//  Hacker terminal color palette — neon green on black
//

import SwiftUI

struct TerminalColors {
    // Primary accent — neon green
    static let green = Color(red: 0.0, green: 1.0, blue: 0.53)       // #00FF88
    static let amber = Color(red: 1.0, green: 0.67, blue: 0.0)       // #FFAA00
    static let red = Color(red: 1.0, green: 0.27, blue: 0.27)        // #FF4444
    static let cyan = Color(red: 0.0, green: 0.67, blue: 1.0)        // #00AAFF
    static let blue = Color(red: 0.0, green: 0.67, blue: 1.0)        // #00AAFF (same as cyan)
    static let magenta = Color(red: 0.8, green: 0.4, blue: 0.8)      // keep for MCP tools

    // Text hierarchy
    static let dim = Color(white: 0.53)                                // #888888
    static let dimmer = Color(white: 0.33)                             // #555555

    // Accent (was Claude orange, now neon green)
    static let prompt = Color(red: 0.0, green: 1.0, blue: 0.53)      // #00FF88

    // Surfaces
    static let background = Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.025)  // subtle green tint
    static let backgroundHover = Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.06)

    // New: borders and glow
    static let border = Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.13)       // #00FF8820
    static let glow = Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.4)          // for .shadow()
    static let surface = Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.03)      // panel gradient top
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add Notchy/Notchy/UI/Components/TerminalColors.swift
git commit -m "feat: replace color palette with neon green hacker terminal theme"
```

---

### Task 2: Update MascotColorPreset default

**Files:**
- Modify: `Notchy/Notchy/UI/Components/Mascots/MascotType.swift` (lines 44-50)

- [ ] **Step 1: Update the `claude` preset color to neon green**

Change line 45 from:
```swift
case .claude: Color(red: 0.85, green: 0.47, blue: 0.34)
```
to:
```swift
case .claude: Color(red: 0.0, green: 1.0, blue: 0.53)
```

And update the display name on line 56 from `"Claude"` to `"Hacker"` (not "Neon" — that name is already used by the `.green` preset).

- [ ] **Step 2: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add Notchy/Notchy/UI/Components/Mascots/MascotType.swift
git commit -m "feat: update default mascot color preset from claude orange to neon green"
```

---

### Task 3: Update ProcessingSpinner color

**Files:**
- Modify: `Notchy/Notchy/UI/Components/ProcessingSpinner.swift` (line 68)

- [ ] **Step 1: Change spinner color to use TerminalColors.prompt**

Change line 68 from:
```swift
    private let color = Color(red: 0.85, green: 0.47, blue: 0.34)  // Claude orange
```
to:
```swift
    private let color = TerminalColors.prompt
```

Also update the `SpinnerPreview` in `Notchy/Notchy/UI/Components/SpinnerPickerRow.swift` (line 110) from:
```swift
    private let color = Color(red: 0.85, green: 0.47, blue: 0.34)
```
to:
```swift
    private let color = TerminalColors.prompt
```

- [ ] **Step 2: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add Notchy/Notchy/UI/Components/ProcessingSpinner.swift
git commit -m "feat: update spinner color to use TerminalColors.prompt (neon green)"
```

---

### Task 4: Update ActionButton to hacker style

**Files:**
- Modify: `Notchy/Notchy/UI/Components/ActionButton.swift` (full restyle)

- [ ] **Step 1: Update ActionButton fonts and styling**

Change font on line 24 from:
```swift
.font(.system(size: 10, weight: .semibold, design: .rounded))
```
to:
```swift
.font(.system(size: 10, weight: .semibold, design: .monospaced))
```

- [ ] **Step 2: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add Notchy/Notchy/UI/Components/ActionButton.swift
git commit -m "feat: update ActionButton to monospaced font"
```

---

### Task 5: Restyle all picker rows (Mascot, Spinner, Sound, Screen)

**Files:**
- Modify: `Notchy/Notchy/UI/Components/MascotPickerRow.swift`
- Modify: `Notchy/Notchy/UI/Components/SpinnerPickerRow.swift`
- Modify: `Notchy/Notchy/UI/Components/SoundPickerRow.swift`
- Modify: `Notchy/Notchy/UI/Components/ScreenPickerRow.swift`

All four pickers follow the same pattern. Apply these changes to each:

- [ ] **Step 1: Update MascotPickerRow fonts to monospaced**

In `MascotPickerRow.swift`, change all `.font(.system(size: N, weight: .medium))` to `.font(.system(size: N, weight: .medium, design: .monospaced))` and all `.font(.system(size: N))` to `.font(.system(size: N, design: .monospaced))`.

Specifically:
- Header label (line ~29): `.font(.system(size: 11, weight: .medium, design: .monospaced))`
- Current value (line ~35): `.font(.system(size: 10, design: .monospaced))`
- Thumbnail label (line ~91): `.font(.system(size: 8, design: .monospaced))`

- [ ] **Step 2: Update SpinnerPickerRow fonts to monospaced**

Same pattern in `SpinnerPickerRow.swift`:
- Header label: `.font(.system(size: 11, weight: .medium, design: .monospaced))`
- Current value: `.font(.system(size: 10, design: .monospaced))`
- Thumbnail label: `.font(.system(size: 7, design: .monospaced))`

- [ ] **Step 3: Update SoundPickerRow fonts to monospaced**

In `SoundPickerRow.swift`:
- Line 27: `.font(.system(size: 11, weight: .medium, design: .monospaced))`
- Line 33: `.font(.system(size: 10, design: .monospaced))`
- Line 74: `.font(.system(size: 10, design: .monospaced))`

- [ ] **Step 4: Update ScreenPickerRow fonts to monospaced**

In `ScreenPickerRow.swift`:
- Line 30: `.font(.system(size: 11, weight: .medium, design: .monospaced))`
- Line 36: `.font(.system(size: 10, design: .monospaced))`
- Line 102: `.font(.system(size: 10, design: .monospaced))`
- Line 108: `.font(.system(size: 9, design: .monospaced))`

- [ ] **Step 5: Build to verify all pickers compile**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add Notchy/Notchy/UI/Components/MascotPickerRow.swift Notchy/Notchy/UI/Components/SpinnerPickerRow.swift Notchy/Notchy/UI/Components/SoundPickerRow.swift Notchy/Notchy/UI/Components/ScreenPickerRow.swift
git commit -m "feat: update all picker rows to monospaced fonts"
```

---

### Task 6: Update ToolResultViews fonts

**Files:**
- Modify: `Notchy/Notchy/UI/Views/ToolResultViews.swift`

- [ ] **Step 1: Update all non-monospaced fonts to monospaced**

In `ToolResultViews.swift`, the following fonts need `design: .monospaced` added (they already have it on most, but check these):
- Line 55: `.font(.system(size: 10))` → `.font(.system(size: 10, design: .monospaced))`
- Any other `.font(.system(size: N))` without `design: .monospaced`

Also replace any hardcoded `Color.white.opacity(0.7)` text colors that should be `TerminalColors.dim` equivalent.

- [ ] **Step 2: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add Notchy/Notchy/UI/Views/ToolResultViews.swift
git commit -m "feat: update ToolResultViews to monospaced fonts and TerminalColors refs"
```

---

### Task 7: Update MarkdownRenderer colors

**Files:**
- Modify: `Notchy/Notchy/UI/Components/MarkdownRenderer.swift`

- [ ] **Step 1: Update code block styling to neon green**

In the markdown renderer, find where code block colors are set. Change:
- Code block text color from cyan to `TerminalColors.prompt` (neon green)
- Code block background to `TerminalColors.surface` or equivalent green tint
- Heading colors to white (keep as-is if already white)

Read the file first to find exact line numbers and current values.

- [ ] **Step 2: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add Notchy/Notchy/UI/Components/MarkdownRenderer.swift
git commit -m "feat: update MarkdownRenderer to neon green code blocks"
```

---

## Chunk 2: Layout Restructuring — Navigation, Sessions, Settings, Closed State

### Task 8: Replace hamburger menu with segmented control

**Files:**
- Modify: `Notchy/Notchy/UI/Views/NotchView.swift` (the `openedHeaderContent` computed property, ~lines 312-343)

- [ ] **Step 1: Replace hamburger button with segmented control**

In `NotchView.swift`, replace the `openedHeaderContent` view builder. Current code has a hamburger `Button` with `line.3.horizontal` / `xmark` icon. Replace with a segmented control:

```swift
@ViewBuilder
private var openedHeaderContent: some View {
    HStack(spacing: 12) {
        if !showClosedActivity {
            MascotIcon(size: 14)
                .matchedGeometryEffect(
                    id: "crab",
                    in: activityNamespace,
                    isSource: !showClosedActivity
                )
                .padding(.leading, 8)
        }

        Spacer()

        if case .chat = viewModel.contentType {
            // Back button when in chat
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.exitChat()
                }
            } label: {
                Text("←")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(TerminalColors.prompt)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            // Segmented control: Sessions | Config
            HStack(spacing: 0) {
                segmentButton("Sessions", isActive: viewModel.contentType == .instances) {
                    viewModel.showInstances()
                }
                segmentButton("Config", isActive: viewModel.contentType == .menu) {
                    viewModel.showMenu()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(TerminalColors.border, lineWidth: 1)
            )
        }
    }
}

private func segmentButton(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
    Button {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            action()
        }
    } label: {
        Text(title)
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .foregroundColor(isActive ? TerminalColors.prompt : TerminalColors.dimmer)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isActive ? TerminalColors.backgroundHover : Color.clear)
            )
    }
    .buttonStyle(.plain)
}
```

- [ ] **Step 2: Add `showInstances()` and `showMenu()` to NotchViewModel**

`exitChat()` already exists in NotchViewModel. Add the two new tab-switching methods:

```swift
func showInstances() {
    contentType = .instances
}

func showMenu() {
    contentType = .menu
}
```

Note: `.chat(session)` has an associated value, so use `if case .chat = viewModel.contentType` for pattern matching (not `==`).

- [ ] **Step 3: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add Notchy/Notchy/UI/Views/NotchView.swift
git commit -m "feat: replace hamburger menu with segmented control navigation"
```

---

### Task 9: Move idle mascot to left side + add glow

**Files:**
- Modify: `Notchy/Notchy/UI/Views/NotchView.swift` (the `headerRow` computed property, ~lines 231-303)

- [ ] **Step 1: Move idle mascot from center to left-aligned**

In `NotchView.swift`'s `headerRow`, find the `else if !showClosedActivity` block (idle state). Currently the mascot is centered with `.frame(width: closedNotchSize.width - 20)`. Change it to left-aligned using the same `sideWidth` as the active states:

Replace:
```swift
} else if !showClosedActivity {
    // Idle state: mascot centered in the notch with breathing animation
    MascotIcon(size: 14)
        .opacity(breatheOpacity)
        .matchedGeometryEffect(id: "crab", in: activityNamespace, isSource: !showClosedActivity)
        .frame(width: closedNotchSize.width - 20)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                breatheOpacity = 0.55
            }
        }
        .onDisappear {
            breatheOpacity = 0.35
        }
```

With:
```swift
} else if !showClosedActivity {
    // Idle state: mascot on left side (camera in center of notch)
    MascotIcon(size: 14)
        .opacity(breatheOpacity)
        .shadow(color: TerminalColors.glow.opacity(breatheOpacity * 0.6), radius: 6)
        .matchedGeometryEffect(id: "crab", in: activityNamespace, isSource: !showClosedActivity)
        .frame(width: sideWidth)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                breatheOpacity = 0.55
            }
        }
        .onDisappear {
            breatheOpacity = 0.35
        }

    // Fill remaining notch width (no expansion)
    Spacer()
        .frame(width: closedNotchSize.width - sideWidth - cornerRadiusInsets.closed.top)
```

- [ ] **Step 2: Add glow to active mascot and indicators**

In the same `headerRow`, add `.shadow()` glow to the active mascot and right-side indicators:

After `MascotIcon(size: 14, animate: isProcessing)` in the `showClosedActivity` block, add:
```swift
.shadow(color: TerminalColors.glow, radius: 6)
```

After each right-side indicator (`PermissionIndicatorIcon`, `ProcessingSpinner`, `ReadyForInputIndicatorIcon`), add appropriate glow:
```swift
.shadow(color: TerminalColors.glow, radius: 4)
```

- [ ] **Step 3: Fix hardcoded orange color for PermissionIndicatorIcon**

In `NotchView.swift`, find the `PermissionIndicatorIcon` call (around line 273). Change:
```swift
PermissionIndicatorIcon(
    size: 14,
    color: Color(red: 0.85, green: 0.47, blue: 0.34)
)
```
to:
```swift
PermissionIndicatorIcon(
    size: 14,
    color: TerminalColors.amber
)
```

- [ ] **Step 4: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add Notchy/Notchy/UI/Views/NotchView.swift
git commit -m "feat: move idle mascot to left side, add neon glow effects"
```

---

### Task 10: Restructure NotchMenuView to grouped panels

**Files:**
- Modify: `Notchy/Notchy/UI/Views/NotchMenuView.swift` (full restructure)

- [ ] **Step 1: Rewrite NotchMenuView body with grouped panels**

Replace the current body (flat rows with section headers and dividers) with grouped panels. The structure becomes:

```swift
var body: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: 8) {
            // DISPLAY panel
            settingsPanel(header: "DISPLAY") {
                ScreenPickerRow()
                MascotPickerRow()
                SpinnerPickerRow()
                SoundPickerRow()
            }

            // SYSTEM panel
            settingsPanel(header: "SYSTEM") {
                launchAtLoginRow
                accessibilityRow
                tmuxStatusRow
                hookStatusRow
            }

            // ABOUT panel
            settingsPanel(header: "ABOUT") {
                githubRow
                quitRow
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}
```

- [ ] **Step 2: Add the settingsPanel helper**

```swift
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
```

- [ ] **Step 3: Update toggle styling for launchAtLoginRow**

Change the checkbox icon styling. Replace the `checkmark.square.fill` / `square` pattern with ON/OFF badges:

```swift
// Replace the Image(systemName:) toggle with:
if launchAtLogin {
    Text("ON")
        .font(.system(size: 8, weight: .bold, design: .monospaced))
        .foregroundColor(.black)
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
        .background(TerminalColors.prompt)
        .cornerRadius(3)
} else {
    Text("OFF")
        .font(.system(size: 8, weight: .bold, design: .monospaced))
        .foregroundColor(TerminalColors.dimmer)
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(TerminalColors.dimmer, lineWidth: 1)
        )
}
```

- [ ] **Step 4: Update all fonts in menu rows to monospaced**

For every row in the menu (launchAtLoginRow, accessibilityRow, tmuxStatusRow, hookStatusRow, githubRow, quitRow):
- Change `.font(.system(size: 11))` → `.font(.system(size: 11, design: .monospaced))`
- Change `.font(.system(size: 10))` → `.font(.system(size: 10, design: .monospaced))`
- Change `.font(.system(size: 9, weight: .semibold))` section headers are now handled by `settingsPanel`

Remove the old `sectionHeader()` and `divider` helpers (no longer needed — panels replace them).

- [ ] **Step 5: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add Notchy/Notchy/UI/Views/NotchMenuView.swift
git commit -m "feat: restructure settings into grouped panels with neon styling"
```

---

### Task 11: Restructure ClaudeInstancesView to dashboard panels

**Files:**
- Modify: `Notchy/Notchy/UI/Views/ClaudeInstancesView.swift` (full restructure)

- [ ] **Step 1: Rewrite session row as dashboard panel**

Replace the current session row (simple HStack with status dot + project name + buttons) with a rich dashboard panel. Read the file first to understand the current structure, then replace the session row view:

```swift
private func sessionPanel(_ session: SessionState) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        // Top row: project name + status badge
        HStack {
            Text(session.projectName)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            statusBadge(for: session)
        }

        // Phase + elapsed time
        HStack(spacing: 6) {
            Circle()
                .fill(phaseColor(session.phase))
                .frame(width: 6, height: 6)
                .opacity(session.phase == .processing ? pulseOpacity : 0.8)

            Text(phaseLabel(session.phase))
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(phaseColor(session.phase))

            if let lastActivity = session.lastActivity {
                Text("· \(elapsedString(since: lastActivity))")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(TerminalColors.dimmer)
            }
        }

        // Last tool call (if available)
        if let toolName = session.lastToolName {
            Text("last: \(toolName)")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(TerminalColors.dimmer)
                .lineLimit(1)
        }

        // Cosmetic progress bar
        if session.phase == .processing {
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(TerminalColors.prompt.opacity(progressOpacity(segment: i)))
                        .frame(height: 2)
                }
            }
        }

        // Approval buttons (if needed)
        if session.phase.isWaitingForApproval {
            approvalButtons(for: session)
        }
    }
    .padding(10)
    .background(
        RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(
                    colors: [panelGradientTop(session.phase), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    )
    .overlay(
        RoundedRectangle(cornerRadius: 6)
            .strokeBorder(panelBorderColor(session.phase), lineWidth: 1)
    )
}
```

- [ ] **Step 2: Add helper methods**

```swift
private func statusBadge(for session: SessionState) -> some View {
    let (text, color) = statusBadgeInfo(session.phase)
    return Text(text)
        .font(.system(size: 7, weight: .bold, design: .monospaced))
        .foregroundColor(color)
        .padding(.horizontal, 5)
        .padding(.vertical, 1)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(color.opacity(0.4), lineWidth: 1)
        )
}

private func phaseLabel(_ phase: SessionPhase) -> String {
    switch phase {
    case .processing: "processing"
    case .compacting: "compacting"
    case .waitingForApproval: "approval"
    case .waitingForInput: "done"
    default: "idle"
    }
}

private func statusBadgeInfo(_ phase: SessionPhase) -> (String, Color) {
    switch phase {
    case .processing, .compacting: ("LIVE", TerminalColors.prompt)
    case .waitingForApproval, .waitingForApproval: ("WAIT", TerminalColors.amber)
    case .waitingForInput: ("DONE", TerminalColors.prompt)
    default: ("IDLE", TerminalColors.dimmer)
    }
}

private func panelGradientTop(_ phase: SessionPhase) -> Color {
    switch phase {
    case .processing, .compacting: TerminalColors.surface
    case .waitingForApproval, .waitingForApproval: Color(red: 1.0, green: 0.67, blue: 0.0).opacity(0.03)
    default: TerminalColors.surface
    }
}

private func panelBorderColor(_ phase: SessionPhase) -> Color {
    switch phase {
    case .waitingForApproval, .waitingForApproval: TerminalColors.amber.opacity(0.13)
    default: TerminalColors.border
    }
}

private func elapsedString(since date: Date) -> String {
    let seconds = Int(Date().timeIntervalSince(date))
    let minutes = seconds / 60
    let secs = seconds % 60
    return minutes > 0 ? "\(minutes)m \(secs)s" : "\(secs)s"
}
```

- [ ] **Step 3: Add animation state for progress bar and pulse**

Add to the view:
```swift
@State private var progressPhase: Int = 0
@State private var pulseOpacity: Double = 0.8
private let progressTimer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

private func progressOpacity(segment: Int) -> Double {
    let active = progressPhase % 3
    return segment == active ? 1.0 : 0.15
}
```

Add pulse animation in `.onAppear`:
```swift
.onAppear {
    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
        pulseOpacity = 0.3
    }
}
```

And in the body, add:
```swift
.onReceive(progressTimer) { _ in
    progressPhase += 1
}
```

- [ ] **Step 4: Restyle approval buttons to neon**

```swift
private func approvalButtons(for session: SessionState) -> some View {
    HStack(spacing: 6) {
        Button("ALLOW") { /* existing approve action */ }
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(TerminalColors.prompt)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(TerminalColors.prompt.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(TerminalColors.prompt.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(4)
            .buttonStyle(.plain)

        Button("DENY") { /* existing deny action */ }
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(TerminalColors.red)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(TerminalColors.red.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(TerminalColors.red.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(4)
            .buttonStyle(.plain)

        Spacer()
    }
}
```

- [ ] **Step 5: Update empty state**

```swift
Text("No active sessions")
    .font(.system(size: 12, design: .monospaced))
    .foregroundColor(TerminalColors.dimmer)
```

- [ ] **Step 6: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 7: Commit**

```bash
git add Notchy/Notchy/UI/Views/ClaudeInstancesView.swift
git commit -m "feat: restructure session list into dashboard panels with status badges and progress bars"
```

---

### Task 12: Restyle ChatView to hacker theme

**Files:**
- Modify: `Notchy/Notchy/UI/Views/ChatView.swift`

- [ ] **Step 1: Update user message bubble styling**

Find the user bubble (around line 82-92). Change background from `Color.white.opacity(0.15)` to green-tinted:

```swift
.background(TerminalColors.prompt.opacity(0.06))
.overlay(
    RoundedRectangle(cornerRadius: 12)
        .strokeBorder(TerminalColors.border, lineWidth: 1)
)
```

- [ ] **Step 2: Update all fonts to monospaced where not already**

Change `.font(.system(size: 11))` (line 86, user text) to `.font(.system(size: 11, design: .monospaced))`.

Change `.font(.system(size: 11, weight: .medium))` (approval buttons lines 300, 320) to `.font(.system(size: 11, weight: .medium, design: .monospaced))`.

- [ ] **Step 3: Update approval bar buttons to neon style**

Replace the Allow/Deny buttons in the approval bar (around lines 289-330) with the same neon style as the session panel approval buttons:
- Allow: green border, green text, green tinted background
- Deny: red border, red text, red tinted background

- [ ] **Step 4: Update input bar styling**

The text field (around line 344-369) — change send button from `TerminalColors.cyan` to `TerminalColors.prompt`.

- [ ] **Step 5: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add Notchy/Notchy/UI/Views/ChatView.swift
git commit -m "feat: restyle ChatView with neon green hacker theme"
```

---

### Task 13: Update ClosedStatePreview and fix hardcoded colors

**Files:**
- Modify: `Notchy/Notchy/UI/Views/ClosedStatePreview.swift`

- [ ] **Step 1: Replace all hardcoded orange colors**

Find `Color(red: 0.85, green: 0.47, blue: 0.34)` (lines ~111, ~153) and replace with `TerminalColors.prompt`.

- [ ] **Step 2: Update fonts to monospaced**

Change any `.font(.system(size: N))` without `design: .monospaced` to include it.

- [ ] **Step 3: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add Notchy/Notchy/UI/Views/ClosedStatePreview.swift
git commit -m "feat: update ClosedStatePreview to neon green theme, remove hardcoded colors"
```

---

### Task 14: Update StatusIcons with glow effects

**Files:**
- Modify: `Notchy/Notchy/UI/Components/StatusIcons.swift`

- [ ] **Step 1: Add glow shadow to animated status icons**

Read `StatusIcons.swift` and add `.shadow(color: TerminalColors.glow, radius: 4)` to the `RunningIcon` view (the rotating hourglass). Ensure all default color parameters use `TerminalColors` references rather than hardcoded values.

- [ ] **Step 2: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add Notchy/Notchy/UI/Components/StatusIcons.swift
git commit -m "feat: add neon glow to status icons"
```

---

### Task 15: Update NotchHeaderView with glow on indicators

**Files:**
- Modify: `Notchy/Notchy/UI/Views/NotchHeaderView.swift`

- [ ] **Step 1: Add glow to PermissionIndicatorIcon and ReadyForInputIndicatorIcon**

Read `NotchHeaderView.swift`. The `PermissionIndicatorIcon` and `ReadyForInputIndicatorIcon` are Canvas-based pixel art icons. Add `.shadow(color: TerminalColors.glow, radius: 4)` to each icon's view body after the `.frame()` modifier.

Also ensure any hardcoded color defaults use `TerminalColors` references.

- [ ] **Step 2: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug build 2>&1 | tail -3`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add Notchy/Notchy/UI/Views/NotchHeaderView.swift
git commit -m "feat: add neon glow to permission and ready-for-input indicators"
```

---

### Task 16: Final build verification and visual test

- [ ] **Step 1: Regenerate Xcode project**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodegen generate`

- [ ] **Step 2: Full clean build**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild -project Notchy.xcodeproj -scheme Notchy -configuration Debug clean build 2>&1 | tail -5`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Launch and visual test**

Run the app from Xcode (Cmd+R) and verify:
1. Closed notch: mascot on LEFT side with green glow breathing
2. Open notch: segmented control `[Sessions | Config]` in header
3. Sessions tab: dashboard panels with LIVE/WAIT badges
4. Config tab: grouped panels with DISPLAY/SYSTEM/ABOUT sections
5. All text is monospaced
6. All accents are neon green (#00FF88)
7. Spinners render in neon green
8. Permission indicator is neon amber

- [ ] **Step 4: Take screenshot for verification**

Run: `screencapture -R 500,0,600,50 /tmp/notch-final.png`

- [ ] **Step 5: Commit any final fixes**

```bash
git add -A
git commit -m "feat: complete hacker terminal UI redesign"
```

---

**Notes for implementer:**
- `SessionPhase` has associated values (e.g., `.waitingForApproval(PermissionContext)`) — use pattern matching, not `==`
- `SessionState.projectName` is non-optional `String` — don't use `??`
- `SessionState.lastToolName` is a convenience property — use it directly
- `TerminalColors` is a `struct`, not an `enum`
- All files live under `Notchy/Notchy/` (double Notchy prefix)
- After any structural change, run `xcodegen generate` before building
