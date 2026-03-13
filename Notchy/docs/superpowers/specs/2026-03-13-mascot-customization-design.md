# Mascot Customization Design

## Goal

Let users choose their notch mascot character and its color from the settings menu. Ships with 6 pixel art mascots (crab, robot, ghost, cat, skull, alien) and 6 color presets.

## Architecture

### Storage

Two new computed properties on the existing `Settings` enum using `UserDefaults.standard` (matching the existing pattern):

- `mascotType: String` — default `"crab"`. One of: `crab`, `robot`, `ghost`, `cat`, `skull`, `alien`.
- `mascotColor: String` — default `"claude"`. One of: `claude`, `green`, `pink`, `blue`, `mono`, `ember`.

### Mascot Enum

Instead of a protocol with static methods, use an enum for simplicity:

```swift
enum MascotType: String, CaseIterable, Sendable {
    case crab, robot, ghost, cat, skull, alien

    var displayName: String { ... }

    func draw(in context: GraphicsContext, size: CGFloat, color: Color, animationPhase: Int) { ... }
}
```

Each case has its own drawing logic in the `draw` method. This avoids metatype gymnastics and is simpler to work with.

### File Structure

```
UI/Components/Mascots/
  MascotType.swift            — enum with draw method, dispatches to per-mascot functions
  CrabMascot.swift            — crab drawing function (refactored from ClaudeCrabIcon)
  RobotMascot.swift           — robot drawing function
  GhostMascot.swift           — ghost drawing function
  CatMascot.swift             — cat drawing function
  SkullMascot.swift           — skull drawing function
  AlienMascot.swift           — alien drawing function
  MascotIcon.swift            — SwiftUI view, drop-in replacement for ClaudeCrabIcon
UI/Components/
  MascotPickerRow.swift       — settings UI for mascot + color selection
```

### MascotIcon (Drop-in Replacement)

```swift
struct MascotIcon: View {
    let size: CGFloat
    var animate: Bool = false
    var colorOverride: Color? = nil  // optional per-instance override

    var body: some View {
        // Canvas that calls MascotType(rawValue: Settings.mascotType).draw(...)
        // Color: colorOverride ?? MascotColorPreset.resolve(Settings.mascotColor)
    }
}
```

- `colorOverride` preserves the ability to pass explicit colors (e.g., in previews or special states).
- When nil, reads from `Settings.mascotColor`.

### Uniform Aspect Ratio

All mascots render into a **square bounding box** (size × size). This ensures layout does not shift when users switch mascots. The current crab has a wider aspect ratio (66:52) — it will be refactored to fit a square frame, with the body scaled to fill the width.

### Replaces `ClaudeCrabIcon` in:

- `NotchView.swift` — idle mascot (centered, dim), active mascot (left side, animated)
- `NotchHeaderView.swift` — opened header crab
- `ClosedStatePreview.swift` — all 6 preview references

After migration, `ClaudeCrabIcon` is deleted. The crab drawing logic moves to `CrabMascot.swift`.

### MascotPickerRow (Settings UI)

A settings section with two parts:

1. **Character Grid** — 3×2 grid of mascot thumbnails. Each is a small Canvas preview (24×24) with the mascot name below. Selected one has a highlight border.
2. **Color Presets** — horizontal row of 6 colored circles. Tap to select. Selected one has a checkmark overlay.

### Color Presets

| Key | Name | RGB |
|-----|------|-----|
| `claude` | Claude Orange | (217, 120, 87) |
| `green` | Neon Green | (100, 255, 150) |
| `pink` | Pastel Pink | (255, 150, 200) |
| `blue` | Ice Blue | (100, 180, 255) |
| `mono` | Monochrome | (200, 200, 220) |
| `ember` | Ember | (255, 100, 80) |

Resolved via a `MascotColorPreset` enum:

```swift
enum MascotColorPreset: String, CaseIterable {
    case claude, green, pink, blue, mono, ember

    var color: Color { ... }
    var displayName: String { ... }
}
```

### Integration Points

- **`Settings.swift`** — add `mascotType` and `mascotColor` computed properties.
- **`NotchMenuView.swift`** — add `MascotPickerRow()` section between Display and Sound sections.
- **`NotchView.swift`** — replace all `ClaudeCrabIcon(...)` with `MascotIcon(...)`.
- **`NotchHeaderView.swift`** — replace `ClaudeCrabIcon` in opened header with `MascotIcon`.
- **`ClosedStatePreview.swift`** — replace all `ClaudeCrabIcon` references with `MascotIcon`.
- **`NotchHeaderView.swift`** — delete `ClaudeCrabIcon` struct after migration.

### Timer / Animation

`MascotIcon` owns a single `Timer.publish(every: 0.15)`. The timer phase only increments when `animate == true`. When `animate` is false, the timer still fires but the phase stays frozen — this matches the current crab behavior and keeps implementation simple. The power cost of a 0.15s timer on a menu bar app is negligible.

### Mascot Designs (Pixel Art Specifications)

All mascots are drawn into a normalized square coordinate system (52×52 logical pixels, scaled to the requested `size`). Each has:

- A main body shape
- Eyes (black pixels)
- A unique animation (4-phase cycle at 0.15s intervals, same as current crab)

**Crab**: Existing design — body, antennae, 4 legs, walking animation. Refactored to fit square frame.
**Robot**: Boxy head with antenna on top, square body, square eyes. Animation: antenna height oscillates.
**Ghost**: Rounded top dome, wavy bottom edge (3 scallops), hollow oval eyes. Animation: vertical position oscillates (float).
**Cat**: Triangular ears, rectangular body, whisker lines, tail to the right. Animation: tail position oscillates.
**Skull**: Rounded cranium, jaw section, large eye sockets, nose hole, teeth. Animation: jaw gap oscillates (open/close).
**Alien**: Large oval head, small body, huge eyes with pupils, thin legs. Animation: pupil size changes (blink).

## Sound Fix: Permission Request Notification

**Bug:** When Claude needs tool approval (permission request), no sound plays. The notch opens visually but there's no audio alert. Users can miss permission requests if they're not looking at the screen.

**Fix:** In `NotchView.handlePendingSessionsChange`, play the notification sound when new permission requests arrive AND the terminal is not visible. Same logic as the existing waiting-for-input sound:

```swift
if !newPendingIds.isEmpty
    && viewModel.status == .closed
    && !TerminalVisibilityDetector.isTerminalVisibleOnCurrentSpace()
{
    NSSound(named: Settings.notificationSound)?.play()
    viewModel.notchOpen(reason: .notification)
}
```

This ensures both attention-needed events (permission requests and task completion) produce an audible notification.

## Non-Goals

- No custom color picker / hex input (presets only, keeps it simple)
- No importing custom sprites
- No per-state mascot selection (same mascot for all states)
- No mascot animation speed customization
