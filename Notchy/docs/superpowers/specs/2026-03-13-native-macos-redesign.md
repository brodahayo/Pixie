# Pixie Native macOS UI Redesign

## Goal

Replace the hacker terminal aesthetic (neon green, monospaced fonts, custom controls) with a native macOS design using system fonts, system colors, frosted glass materials, and standard SwiftUI controls — while keeping the pixel art mascots and spinners as personality elements.

## Constraints

- Dark mode only (no light mode support)
- Pixel art mascots, spinners, and zzZ sleep animation are kept as-is
- All existing functionality preserved — no feature changes, only visual
- Must work in the notch's compact space (body text 12pt, not 13pt)

## Architecture: Full Retheme (Single Sweep)

Replace `TerminalColors` with semantic system colors and update all UI files in one pass. Incremental migration rejected because the terminal aesthetic is too deeply embedded — partial conversion would look inconsistent.

---

## 1. Color System

**Delete `TerminalColors.swift`. Replace with `AppColors.swift`:**

| Semantic Role | SwiftUI Value |
|---|---|
| Primary text | `Color.primary` (white in dark mode) |
| Secondary text | `Color.secondary` (system gray) |
| Tertiary text | `Color(white: 0.4)` |
| Accent / links | `Color.accentColor` (system blue) |
| Success / running | `Color.green` |
| Approval / warning | `Color.orange` |
| Error / deny | `Color.red` |
| Borders / dividers | `Color.separator` |
| Backgrounds | `.ultraThinMaterial` (frosted glass) |
| Surfaces / cards | `Color(white: 1).opacity(0.05)` (subtle lift) |
| Hover states | Native hover (no manual color) |
| Info / tools (was cyan) | `Color.blue` |
| MCP tools (was magenta) | `Color.purple` |
| Idle / dim | `Color.secondary` |

**Removed concepts:** `glow`, `prompt`, `backgroundHover`, `dimmer`, `surface`, `border` — all replaced by system equivalents.

**Kept:** Mascot colors (`MascotColorPreset`) are unchanged. The mascot, spinner, and zzZ still use the user-selected mascot color.

---

## 2. Typography

| Element | Font | Size | Weight |
|---|---|---|---|
| Body text / labels | `.system` (SF Pro) | 12pt | `.regular` |
| Primary labels (setting names) | `.system` | 13pt | `.regular` |
| Section headers | `.system` | 11pt | `.semibold`, uppercase |
| Secondary / meta text | `.system` | 11pt | `.regular`, `.secondary` color |
| Status badges (LIVE/WAIT/DONE) | `.system` | 10pt | `.semibold`, capsule bg |
| Code content (tool names, file paths, bash output, diffs) | `.monospaced` | 12pt | `.regular` |
| Spinners | `.monospaced` | unchanged | unchanged |
| zzZ sleep indicator | `.monospaced` | unchanged | unchanged |

**Rule:** Monospaced font is only used for code-like content, spinners, and zzZ. Everything else uses the system font.

---

## 3. Spacing & Layout

| Element | Value |
|---|---|
| Row padding | Handled by native `Form`/`List` (automatic) |
| Section gaps | Handled by native `Section` spacing (automatic) |
| Corner radius (grouped rows) | 10px (native `.insetGrouped` default) |
| Corner radius (badges/chips) | 20px (pill shape) |
| Card padding | 12px |
| Card corner radius | 10px |
| Card spacing | 6px gap |
| Content area padding | 8px |

**Key principle:** Let SwiftUI's native `Form`, `List`, and `Section` handle padding, separators, and alignment. No manual pixel values for standard row layouts.

---

## 4. Approval Buttons

**Style: White pill Allow + gray pill Deny**

- **Allow:** White background (`#FFFFFF`), black text, 20px border radius (pill), 13pt semibold, `7px 22px` padding
- **Deny:** `Color(white: 1).opacity(0.1)` background, `Color(white: 1).opacity(0.7)` text, same pill shape
- **Smaller variant** (inline in session cards): 12pt, 16px border radius, `5px 16px` padding

**Implementation:** Use a custom `ButtonStyle` (`PillButtonStyle`) since `.borderedProminent` with `.tint(.white)` does not reliably produce a white-background pill on macOS. The custom style directly sets background, foreground, shape, and padding:

```swift
struct PillButtonStyle: ButtonStyle {
    let isPrimary: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 22)
            .padding(.vertical, 7)
            .background(isPrimary ? Color.white : Color.white.opacity(0.1))
            .foregroundColor(isPrimary ? .black : Color.white.opacity(0.7))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
```

---

## 5. View-by-View Changes

### 5.1 NotchView — Moderate change

- Keep the mascot + center black rectangle + right indicator layout exactly as-is (closed state)
- Keep zzZ animation, breathing opacity, all current closed-state behavior
- Replace all `TerminalColors` references (~10+):
  - `TerminalColors.glow` shadows → `Color.white.opacity(0.15)` shadow
  - `TerminalColors.prompt` (back button) → `Color.accentColor`
  - `TerminalColors.border` (segmented control border) → `Color.separator`
  - `TerminalColors.dimmer` (inactive segment text) → `Color.secondary`
  - `TerminalColors.backgroundHover` (active segment) → native styling
- Segmented control: replace custom implementation with native `Picker(.segmented)`
- Opened content background: `.ultraThinMaterial` applied to the content area inside the notch (the outer notch shell remains `.black` to blend with the physical hardware notch)
- Mascot size stays at 18pt

### 5.2 NotchMenuView (settings) — Biggest change

**Replace entirely with native SwiftUI `Form`:**

```
Form {
    Section("Display") {
        // Screen picker
        // Mascot picker (DisclosureGroup with grid preview)
        // Color picker (inline circles)
        // Spinner picker (DisclosureGroup with grid preview)
        // Sound picker
    }
    Section("System") {
        Toggle("Launch at Login", isOn: $launchAtLogin)
        // Accessibility status row
        // tmux status row
        // Claude Hooks row with Reinstall button
    }
    Section("About") {
        // Check for Updates button
        // GitHub link
        // Quit Pixie button (red text)
    }
}
.formStyle(.grouped)
```

- Native `Toggle` for Launch at Login (replaces custom ON/OFF badges)
- Native navigation chevrons for pickers
- Mascot and spinner pickers keep their custom grid previews inside `DisclosureGroup`
- Status indicators: `Color.green` checkmark for granted/installed, `Color.orange` for missing
- SF Symbols for row icons (replacing emoji where appropriate)
- Section headers: automatic uppercase gray styling from `Form`

**Note:** SwiftUI `Form` with `.formStyle(.grouped)` may apply large default insets for the compact notch panel. Use `.listRowInsets(EdgeInsets(...))` and `.scrollContentBackground(.hidden)` to control padding and remove default backgrounds if needed.

### 5.3 ClaudeInstancesView (sessions) — Moderate change

- Use `List` or `VStack` with consistent card styling
- Session cards: `Color(white: 1).opacity(0.05)` background, 10px corner radius
- Status badges: capsule-shaped with tinted backgrounds
  - LIVE: `Color.green.opacity(0.15)` bg, `Color.green` text
  - WAIT: `Color.orange.opacity(0.15)` bg, `Color.orange` text
  - DONE: `Color.secondary.opacity(0.15)` bg, `Color.secondary` text
- Status dot + phase text + elapsed time in system font 11pt
- Last tool name: monospaced 10pt, secondary color
- Progress bar: keep 8-segment custom bar, use system colors (`Color.green`, `Color.orange`, `Color.secondary`)
- Approval row: white pill Allow + gray pill Deny (smaller variant)
- Sort order unchanged: approval > waiting > processing > idle > ended

### 5.4 ChatView (conversation) — Light change

- System font for all message text
- User bubbles: `Color.accentColor.opacity(0.1)` background, 12px radius, right-aligned
- Assistant bubbles: `Color(white: 1).opacity(0.05)` background, 12px radius, left-aligned
- Tool call rows: monospaced font for tool name, system font for file path
  - Status indicators: system color dots (green checkmark, orange spinner, red X)
  - Expandable results: keep current expand/collapse behavior
- Thinking blocks: collapsible, italic, secondary color
- Approval bar (bottom): white pill Allow + gray pill Deny with tool info above
- Input field: native `TextField` with `.textFieldStyle(.roundedBorder)` or custom rounded style
- Send button: `Color.accentColor` circle with arrow

### 5.5 ToolResultViews — Moderate change

- Keep `.monospaced` for all code content (file paths, line numbers, bash output, diffs, grep results)
- System font for labels and headers
- System colors for status (green for success, red for error, orange for pending)
- Remove neon green tinted code block backgrounds — use `Color(white: 1).opacity(0.03)` instead
- Diff colors: `Color.green` for additions, `Color.red` for deletions (system colors)

### 5.6 MarkdownRenderer — Light change

- Keep monospaced for code blocks and inline code
- System font for body text, headings, lists, block quotes
- Code block background: `Color(white: 1).opacity(0.03)`
- Link color: `Color.accentColor`
- Heading sizes: keep current scale ratios (1.5x, 1.3x, 1.15x) but with system font

### 5.7 ActionButton — Light change

- System font instead of monospaced
- Use native button styling (`.bordered` or `.borderedProminent`)
- Remove custom border/hover color management

### 5.8 StatusIcons — Light change

- Keep all Canvas-drawn pixel art shapes and animations
- Update default color parameters that reference `TerminalColors`:
  - `TerminalColors.green` → `Color.green`
  - `TerminalColors.amber` → `Color.orange`
  - `TerminalColors.cyan` → `Color.blue`
  - `TerminalColors.dim` → `Color.secondary`
  - `TerminalColors.glow` shadows → `Color.white.opacity(0.15)` or remove

### 5.9 ProcessingSpinner — No change

- Keep all 12 spinner styles, unicode characters, and animation
- Color still driven by mascot color selection

### 5.10 Mascots — No change

- All 6 mascots, 6 color presets, Canvas drawing, animation phases unchanged

### 5.11 NotchHeaderView — Light change

- `PermissionIndicatorIcon` and `ReadyForInputIndicatorIcon` are Canvas-drawn pixel art — keep shapes, update default color parameters:
  - `TerminalColors.amber` → `Color.orange`
  - `TerminalColors.green` → `Color.green`
  - `TerminalColors.glow` → `Color.white.opacity(0.15)` or remove

### 5.12 ClosedStatePreview — Light change

- Update color references to match new system (debug view only)

### 5.13 Window Layer — No change

- `NotchPanel`, `NotchWindowController`, `NotchViewController` unchanged
- Window behavior, hit testing, positioning all preserved

---

## 6. Backgrounds & Materials

| Context | Material |
|---|---|
| Opened notch content area | `.ultraThinMaterial` |
| Session cards | `Color(white: 1).opacity(0.05)` |
| Settings groups | Native `Form` grouped background (automatic) |
| Chat bubbles (user) | `Color.accentColor.opacity(0.1)` |
| Chat bubbles (assistant) | `Color(white: 1).opacity(0.05)` |
| Approval bar | `Color.orange.opacity(0.06)` |
| Tool call rows | `Color(white: 1).opacity(0.03)` |
| Code blocks | `Color(white: 1).opacity(0.03)` |

---

## 7. Files Changed

**Deleted:**
- `TerminalColors.swift`

**Created:**
- `AppColors.swift` (minimal — mostly uses SwiftUI system colors directly, but provides any custom helpers needed)

**Modified (all under `Notchy/UI/`):**
- `Components/ActionButton.swift` — system font, native button style
- `Components/MarkdownRenderer.swift` — system font for non-code, system colors
- `Components/MascotPickerRow.swift` — system font
- `Components/ScreenPickerRow.swift` — system font
- `Components/SoundPickerRow.swift` — system font
- `Components/SpinnerPickerRow.swift` — system font
- `Views/NotchView.swift` — system colors, material backgrounds, native segmented control
- `Views/NotchMenuView.swift` — full rewrite to native `Form`
- `Views/ClaudeInstancesView.swift` — system colors, capsule badges, pill buttons
- `Views/ChatView.swift` — system font, system colors, pill buttons, native input
- `Views/NotchHeaderView.swift` — system colors
- `Views/ToolResultViews.swift` — system font for labels, system colors
- `Views/ClosedStatePreview.swift` — update color references

**Also modified:**
- `Components/StatusIcons.swift` — update `TerminalColors` default parameters to system colors
- `Views/NotchHeaderView.swift` — update `TerminalColors` default parameters in indicator icons

**Unchanged:**
- All mascot files (6 mascots + `MascotType.swift` + `MascotIcon.swift`)
- `ProcessingSpinner.swift`
- `NotchShape.swift`
- All Window layer files (`NotchWindow.swift`, `NotchWindowController.swift`, `NotchViewController.swift`)

---

## 8. What This Does NOT Change

- App functionality (sessions, chat, approvals, hooks, sounds)
- Notch positioning, sizing, or hit testing
- Mascot selection, color presets, or animation
- Spinner styles or animation
- zzZ sleep indicator
- Notification sound behavior
- Window management or screen detection
- Hook installation or socket server
- Sparkle update mechanism
