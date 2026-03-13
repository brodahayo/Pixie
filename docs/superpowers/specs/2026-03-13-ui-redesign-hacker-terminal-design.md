# Notchy UI Redesign: Hacker Terminal

## Goal

Redesign Notchy's visual identity and layout to differentiate it from the original Claude Island project it was forked from, while preserving all existing functionality. The new aesthetic is "Hacker Terminal" — neon green on black, glowing accents, monospaced typography, command center feel.

## Scope

**In scope:** Visual styling, color palette, typography, layout restructuring, navigation pattern change, component restyling.

**Out of scope:** Core logic, session monitoring, hook system, IPC, mascot/spinner functionality (only their visual presentation changes).

---

## 1. Color Palette

Replace the current warm orange / terminal color theme with a neon hacker palette.

### Current → New

| Token | Current | New |
|---|---|---|
| Primary accent | `RGB(0.85, 0.47, 0.34)` (Claude orange) | `#00FF88` (neon green) |
| Secondary accent | — | `#00FF8860` (dimmed green) |
| Warning | `RGB(1.0, 0.7, 0.0)` (amber) | `#FFAA00` (neon amber) |
| Error/deny | `RGB(1.0, 0.3, 0.3)` (red) | `#FF4444` (neon red) |
| Success | `RGB(0.4, 0.75, 0.45)` (green) | `#00FF88` (same as primary) |
| Info/link | `RGB(0.4, 0.6, 1.0)` (blue) | `#00AAFF` (neon cyan-blue) |
| Text primary | White | `#E0E0E0` |
| Text secondary | White 0.4 opacity | `#888888` |
| Text tertiary | White 0.2 opacity | `#555555` |
| Background surface | White 0.05 opacity | `#0A0A0F` or `#00FF8806` (tinted) |
| Background hover | White 0.1 opacity | `#00FF8810` |
| Border | White 0.08 opacity | `#00FF8820` (green-tinted) |
| Divider | White 0.08 opacity | `#00FF8815` |

### File: `TerminalColors.swift`

Redefine all color constants to the new palette. The `prompt` color (currently Claude orange) becomes neon green. Add new properties:

- `glow` — accent color at 40% opacity for `shadow` effects
- `surface` — the tinted background (`#00FF8806`)
- `border` — green-tinted border color

### Glow System

Active/important elements get a subtle glow via SwiftUI `.shadow(color:radius:)`:
- Active states: `Color(#00FF88).opacity(0.4)`, radius 8
- Warning states: `Color(#FFAA00).opacity(0.4)`, radius 6
- Idle elements: no glow

---

## 2. Typography

Switch to monospaced system font globally with letter-spacing on headers.

### Changes

- **All body text**: `.system(size: N, design: .monospaced)` instead of `.system(size: N)`
- **Section headers**: Uppercase, letter-spacing via `.tracking(2)`, size 8-9pt, bold
- **Labels**: Monospaced, size 9-10pt
- **Values**: Monospaced, bold, neon green

### Files affected

Every view and component file that sets `.font()`. The change is mechanical — replace `.system(size: X)` with `.system(size: X, design: .monospaced)` and add `.tracking()` to section headers.

---

## 3. Navigation: Segmented Control

Replace the hamburger menu toggle with a segmented control in the header.

### Current behavior

- Hamburger icon (☰ / ✕) in header toggles between `contentType: .instances` and `.menu`
- `NotchViewModel.contentType` enum: `.instances`, `.menu`, `.chat(session)`

### New behavior

- Segmented control in header: `[Sessions | Config]`
- Active segment: neon green border (`#00FF8840`), background tint (`#00FF8810`), green text
- Inactive segment: `#555555` text, no border, no background
- Pill-shaped container with 1px border in `#00FF8830`
- Spring animation on segment switch (response: 0.3, damping: 0.8)

### Header layout (opened)

```
[Mascot 14pt] ············ [Sessions|Config] segmented control
```

- Mascot on far left (same as current)
- Segmented control on far right (replaces hamburger button)
- When in `.chat` state, segmented control is replaced by a back arrow `←`. Tapping the back arrow returns to the Sessions tab (calls `exitChat()` which sets `contentType = .instances`)
- The `.chat` state is only entered by tapping a session row — it is not a segment in the control

### Files affected

- `NotchView.swift` — replace hamburger `Button` with `SegmentedControl` view in `openedHeaderContent`
- `NotchViewModel` — `toggleMenu()` replaced by `selectTab(_ tab: ContentTab)` or equivalent
- New: `SegmentedControl.swift` component (or inline in header)

---

## 4. Session List: Dashboard Panels

Restructure `ClaudeInstancesView` from simple rows to rich dashboard panels.

### Panel structure per session

```
┌─ 1px green-tinted border, gradient bg ─────────────┐
│ [project-name]  bold white        [LIVE] green badge │
│ ● processing · 2m 14s            accent color text   │
│ last: Edit src/main.swift         dim text            │
│ ▬▬▬▬▬▬▬▬░░░░                     progress segments   │
│                                                       │
│ (if approval needed:)                                 │
│ [ALLOW] green border    [DENY] red border             │
└───────────────────────────────────────────────────────┘
```

### Panel styling

- Border: 1px `#00FF8820`
- Background: `LinearGradient` from `#00FF8808` (top) to transparent (bottom)
- Corner radius: 6pt
- Spacing between panels: 6pt

### Status badges

- `LIVE` — 8pt uppercase monospaced, 1px green border, green text, pill-shaped
- `WAIT` — same but amber
- `DONE` — same but green, filled background

### Progress bar (cosmetic)

- Thin (2pt height) segmented bar at bottom of panel
- 3 segments, purely cosmetic animated pulse (not data-driven — Claude sessions don't expose progress percentage)
- Segments pulse in sequence with a 0.8s staggered animation to indicate activity
- Static (all segments dim) when session is idle/waiting

### Approval buttons

- `ALLOW`: neon green border, green text, green tinted background (`#00FF8830`)
- `DENY`: neon red border, red text, red tinted background (`#FF444430`)
- 8pt uppercase monospaced, pill-shaped, inline at bottom of panel

### Elapsed time

- Use `SessionState.lastActivity` (already available) to compute elapsed time since last activity
- Display as `Xm Xs` next to the phase text
- View-local `Timer` at 1-second interval drives the display update
- No changes to `SessionState` needed

### Last tool call

- Show `SessionState.conversationInfo.lastToolName` (already available, tool name only)
- Dim text, single line, truncated if long
- Format: `last: ToolName` (no arguments — data source only has tool name)

### Empty state

- Monospaced dim text: `No active sessions`
- Optional: blinking cursor after text

### Files affected

- `ClaudeInstancesView.swift` — complete restructure of session rows to panels
- May need `SessionState` to expose last tool call info (check existing data)

---

## 5. Settings: Grouped Panels

Restructure `NotchMenuView` from flat rows to grouped panel sections.

### Panel groups

**DISPLAY panel:**
```
┌─ gradient border ──────────────────────────┐
│ DISPLAY                    section header   │
│ Screen         Built-in Display ▾           │
│ Mascot         Crab ▾                       │
│ Spinner        Tetris ▾                     │
│ Sound          Pop ▾                        │
└─────────────────────────────────────────────┘
```

**SYSTEM panel:**
```
┌─ gradient border ──────────────────────────┐
│ SYSTEM                     section header   │
│ Launch at Login            [ON]             │
│ Accessibility              ● Granted        │
│ tmux                       Not Found        │
│ Claude Hooks     Installed [REINSTALL]      │
└─────────────────────────────────────────────┘
```

**ABOUT panel:**
```
┌─ gradient border ──────────────────────────┐
│ ABOUT                      section header   │
│ GitHub                     →                │
│ Quit Notchy                                 │
└─────────────────────────────────────────────┘
```

### Panel styling

- Same as session panels: 1px `#00FF8820` border, gradient background, 6pt radius
- Section header: 8pt uppercase, `#00FF88`, letter-spacing 1pt, monospaced
- Row label: 9pt monospaced, `#CCCCCC`
- Row value: 9pt monospaced bold, `#00FF88`, right-aligned
- Dropdown indicator: `▾` after expandable values

### Toggle styling

- ON: Filled green badge (`#00FF88` background, black text, bold)
- OFF: Outline badge (`#555555` border, dim text)

### Picker expansion

When a picker row (Mascot, Spinner, Sound, Screen) is tapped:
- The row's `▾` rotates to `▴`
- Grid/list expands below with spring animation
- Picker items styled with green-tinted selection state (same as current, just recolored)

### Files affected

- `NotchMenuView.swift` — restructure from flat VStack to panel groups
- All picker rows (`MascotPickerRow`, `SpinnerPickerRow`, `SoundPickerRow`, `ScreenPickerRow`) — restyle with green accents, monospaced font
- `ActionButton.swift` — restyle to neon green

---

## 6. Closed Notch State

### Idle state

- Mascot on **left side** of notch (not centered) — uses same `sideWidth` frame as the active states
- Camera occupies the physical center of the MacBook notch — content must avoid it
- Idle state does NOT expand the notch (no `expansionWidth`) — mascot fits within the standard notch width, left-aligned
- Neon green glow (`.shadow(color: neonGreen.opacity(0.4), radius: 6)`)
- Breathing opacity: 0.35 → 0.55 on 3s easeInOut loop (same timing, just green glow)
- Right side: empty

### Processing state

- Mascot left (full glow, animated) + Spinner right (neon green)
- Same layout as current, just green instead of orange

### Permission needed

- Mascot left + existing `PermissionIndicatorIcon` (pixel-art question mark) right, recolored to neon amber with amber glow

### Task complete

- Mascot left + `✓` right in neon green with green glow

### Files affected

- `NotchView.swift` — move idle mascot from center to left, add glow modifiers
- `ProcessingSpinner.swift` — change color from Claude orange to neon green
- `NotchHeaderView.swift` — add glow to permission/checkmark indicators

---

## 7. Chat View Restyling

The chat view keeps its structure but gets the hacker treatment.

### Changes

- Message bubbles: green-tinted border instead of white opacity background
- User messages: `#00FF8810` background, `#00FF8830` border
- Tool call rows: neon status dots (green=running, amber=pending, green=success, red=error)
- Input bar: monospaced, neon green cursor/send button
- Approval bar: `ALLOW`/`DENY` styled as neon buttons (same as session panel)
- Markdown code blocks: green-tinted background, neon green text

### Files affected

- `ChatView.swift` — restyle bubbles, input bar, approval buttons
- `MarkdownRenderer.swift` — update code block colors, heading colors

---

## 8. Files Summary

### Modified files

| File | Change type |
|---|---|
| `TerminalColors.swift` | Full rewrite — new color palette |
| `NotchView.swift` | Idle mascot left-aligned, glow effects, segmented control |
| `NotchMenuView.swift` | Restructure to grouped panels |
| `ClaudeInstancesView.swift` | Restructure to dashboard panels |
| `ChatView.swift` | Restyle to hacker theme |
| `NotchHeaderView.swift` | Segmented control, glow on icons |
| `ProcessingSpinner.swift` | Change color to neon green |
| `StatusIcons.swift` | Green glow, updated colors |
| `ActionButton.swift` | Neon green styling |
| `MascotPickerRow.swift` | Green accents, monospaced |
| `SpinnerPickerRow.swift` | Green accents, monospaced |
| `SoundPickerRow.swift` | Green accents, monospaced |
| `ScreenPickerRow.swift` | Green accents, monospaced |
| `MarkdownRenderer.swift` | Green code blocks, updated colors |
| `ClosedStatePreview.swift` | Update to match new styling |
| `ToolResultViews.swift` | Monospaced fonts, green-tinted colors |
| `MascotType.swift` | Update `MascotColorPreset.claude` default to neon green |

### New files

| File | Purpose |
|---|---|
| None expected | Segmented control can be inline in NotchView |

### Unchanged files

- `NotchShape.swift` — bezier curves stay the same
- `Settings.swift` — no new settings needed
- All `Core/` files — logic untouched
- All `Mascots/` files — drawing code unchanged (colors come from presets)

---

## 9. Migration Notes

- The `MascotColorPreset.claude` preset currently maps to orange `(0.85, 0.47, 0.34)`. This should be updated to neon green `#00FF88` as the default, or renamed to `neon` with green as default.
- All `TerminalColors.prompt` references (Claude orange) become neon green.
- **Hardcoded colors**: `NotchView.swift` line 273 and `ClosedStatePreview.swift` lines 111/153 use hardcoded `Color(red: 0.85, green: 0.47, blue: 0.34)` instead of `TerminalColors.prompt`. These must also be updated to use `TerminalColors.prompt` (which will now be neon green).
- No data migration needed — all changes are visual.
- The `contentType` enum in `NotchViewModel` stays the same (`.instances`, `.menu`, `.chat`), just the toggle mechanism changes from hamburger to segmented control.
