# Mascot Customization Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users choose their notch mascot (crab/robot/ghost/cat/skull/alien) and color from settings, and fix the missing permission-request notification sound.

**Architecture:** A `MascotType` enum dispatches Canvas drawing to per-mascot files. `MascotIcon` is a drop-in SwiftUI view replacing `ClaudeCrabIcon`. A `MascotPickerRow` in settings provides mascot + color selection. Permission sound fix is a one-line addition.

**Tech Stack:** Swift 6, SwiftUI Canvas, UserDefaults, xcodegen

**Spec:** `docs/superpowers/specs/2026-03-13-mascot-customization-design.md`

---

## File Structure

```
Files to CREATE:
  Notchy/UI/Components/Mascots/MascotType.swift          — enum + color preset enum
  Notchy/UI/Components/Mascots/CrabMascot.swift           — crab drawing function
  Notchy/UI/Components/Mascots/RobotMascot.swift          — robot drawing function
  Notchy/UI/Components/Mascots/GhostMascot.swift          — ghost drawing function
  Notchy/UI/Components/Mascots/CatMascot.swift            — cat drawing function
  Notchy/UI/Components/Mascots/SkullMascot.swift          — skull drawing function
  Notchy/UI/Components/Mascots/AlienMascot.swift          — alien drawing function
  Notchy/UI/Components/Mascots/MascotIcon.swift           — SwiftUI view (drop-in replacement)
  Notchy/UI/Components/MascotPickerRow.swift              — settings UI

Files to MODIFY:
  Notchy/Core/Settings.swift                              — add mascotType + mascotColor
  Notchy/UI/Views/NotchMenuView.swift                     — add MascotPickerRow section
  Notchy/UI/Views/NotchView.swift                         — replace ClaudeCrabIcon → MascotIcon + permission sound
  Notchy/UI/Views/ClosedStatePreview.swift                — replace ClaudeCrabIcon → MascotIcon

Files to DELETE:
  (ClaudeCrabIcon struct removed from NotchHeaderView.swift after migration)
```

---

## Chunk 1: Foundation

### Task 1: Add Settings Keys

**Files:**
- Modify: `Notchy/Core/Settings.swift`

- [ ] **Step 1: Add mascotType and mascotColor to Settings**

```swift
// Add after launchAtLogin in Settings.swift:

    static var mascotType: String {
        get { UserDefaults.standard.string(forKey: "mascotType") ?? "crab" }
        set { UserDefaults.standard.set(newValue, forKey: "mascotType") }
    }

    static var mascotColor: String {
        get { UserDefaults.standard.string(forKey: "mascotColor") ?? "claude" }
        set { UserDefaults.standard.set(newValue, forKey: "mascotColor") }
    }
```

- [ ] **Step 2: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodegen generate && xcodebuild build -project Notchy.xcodeproj -scheme Notchy -configuration Debug 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Notchy/Core/Settings.swift
git commit -m "feat: add mascotType and mascotColor settings keys"
```

---

### Task 2: Create MascotType and MascotColorPreset Enums

**Files:**
- Create: `Notchy/UI/Components/Mascots/MascotType.swift`

- [ ] **Step 1: Create the Mascots directory**

```bash
mkdir -p /Users/ayo/Desktop/Notchi/Notchy/Notchy/UI/Components/Mascots
```

- [ ] **Step 2: Create MascotType.swift with both enums**

```swift
//
//  MascotType.swift
//  Notchy
//
//  Mascot type and color preset enums
//

import SwiftUI

/// Available mascot characters
enum MascotType: String, CaseIterable, Sendable {
    case crab, robot, ghost, cat, skull, alien

    var displayName: String {
        switch self {
        case .crab: return "Crab"
        case .robot: return "Robot"
        case .ghost: return "Ghost"
        case .cat: return "Cat"
        case .skull: return "Skull"
        case .alien: return "Alien"
        }
    }

    /// Draw this mascot into a Canvas GraphicsContext
    func draw(in context: GraphicsContext, size: CGFloat, color: Color, animationPhase: Int) {
        let scale = size / 52.0
        switch self {
        case .crab: CrabMascot.draw(in: context, scale: scale, color: color, phase: animationPhase)
        case .robot: RobotMascot.draw(in: context, scale: scale, color: color, phase: animationPhase)
        case .ghost: GhostMascot.draw(in: context, scale: scale, color: color, phase: animationPhase)
        case .cat: CatMascot.draw(in: context, scale: scale, color: color, phase: animationPhase)
        case .skull: SkullMascot.draw(in: context, scale: scale, color: color, phase: animationPhase)
        case .alien: AlienMascot.draw(in: context, scale: scale, color: color, phase: animationPhase)
        }
    }
}

/// Color presets for mascots
enum MascotColorPreset: String, CaseIterable, Sendable {
    case claude, green, pink, blue, mono, ember

    var color: Color {
        switch self {
        case .claude: return Color(red: 0.85, green: 0.47, blue: 0.34)
        case .green: return Color(red: 0.39, green: 1.0, blue: 0.59)
        case .pink: return Color(red: 1.0, green: 0.59, blue: 0.78)
        case .blue: return Color(red: 0.39, green: 0.71, blue: 1.0)
        case .mono: return Color(red: 0.78, green: 0.78, blue: 0.86)
        case .ember: return Color(red: 1.0, green: 0.39, blue: 0.31)
        }
    }

    var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .green: return "Neon"
        case .pink: return "Pink"
        case .blue: return "Ice"
        case .mono: return "Mono"
        case .ember: return "Ember"
        }
    }

    /// Resolve a settings string to a Color
    static func resolve(_ key: String) -> Color {
        MascotColorPreset(rawValue: key)?.color
            ?? MascotColorPreset.claude.color
    }
}
```

- [ ] **Step 3: Build to verify** (will fail until mascot draw functions exist — that's expected)

---

### Task 3: Create CrabMascot (Refactor from ClaudeCrabIcon)

**Files:**
- Create: `Notchy/UI/Components/Mascots/CrabMascot.swift`

- [ ] **Step 1: Create CrabMascot.swift**

Extract the drawing logic from `ClaudeCrabIcon` into a static draw function. Fit to a 52×52 square bounding box (the existing crab is 66×52 — center it within the square).

```swift
//
//  CrabMascot.swift
//  Notchy
//
//  Pixel art crab mascot drawing
//

import SwiftUI

enum CrabMascot {
    static func draw(in context: GraphicsContext, scale: CGFloat, color: Color, phase: Int) {
        // The original crab is 66 wide × 52 tall. Scale it down to fit 52×52 box.
        // Apply an additional horizontal scale factor: 52/66 ≈ 0.788
        let hScale = scale * (52.0 / 66.0)
        let vScale = scale

        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
            Path { p in
                p.addRect(CGRect(x: x * hScale, y: y * vScale, width: w * hScale, height: h * vScale))
            }
        }

        // Antennae
        context.fill(rect(0, 13, 6, 13), with: .color(color))
        context.fill(rect(60, 13, 6, 13), with: .color(color))

        // Legs with walking animation
        let legPositions: [CGFloat] = [6, 18, 42, 54]
        let baseLegHeight: CGFloat = 13
        let offsets: [[CGFloat]] = [
            [3, -3, 3, -3],
            [0, 0, 0, 0],
            [-3, 3, -3, 3],
            [0, 0, 0, 0],
        ]
        let currentOffsets = offsets[phase % 4]
        for (i, xPos) in legPositions.enumerated() {
            let h = baseLegHeight + currentOffsets[i]
            context.fill(rect(xPos, 39, 6, h), with: .color(color))
        }

        // Body
        context.fill(rect(6, 0, 54, 39), with: .color(color))

        // Eyes
        context.fill(rect(12, 13, 6, 6.5), with: .color(.black))
        context.fill(rect(48, 13, 6, 6.5), with: .color(.black))
    }
}
```

- [ ] **Step 2: Build to verify**

---

### Task 4: Create RobotMascot

**Files:**
- Create: `Notchy/UI/Components/Mascots/RobotMascot.swift`

- [ ] **Step 1: Create RobotMascot.swift**

```swift
//
//  RobotMascot.swift
//  Notchy
//
//  Pixel art robot mascot drawing
//

import SwiftUI

enum RobotMascot {
    static func draw(in context: GraphicsContext, scale: CGFloat, color: Color, phase: Int) {
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
            Path { p in
                p.addRect(CGRect(x: x, y: y, width: w, height: h))
            }.applying(CGAffineTransform(scaleX: scale, y: scale))
        }

        // Antenna - bobs up/down
        let antennaOffsets: [CGFloat] = [-2, 0, 2, 0]
        let antennaY: CGFloat = antennaOffsets[phase % 4]
        context.fill(rect(23, antennaY, 6, 10), with: .color(color))

        // Head
        context.fill(rect(8, 10, 36, 22), with: .color(color))

        // Body
        context.fill(rect(14, 32, 24, 12), with: .color(color))

        // Arms
        context.fill(rect(6, 32, 8, 10), with: .color(color))
        context.fill(rect(38, 32, 8, 10), with: .color(color))

        // Legs
        context.fill(rect(16, 44, 8, 8), with: .color(color))
        context.fill(rect(28, 44, 8, 8), with: .color(color))

        // Eyes (square)
        context.fill(rect(14, 18, 8, 8), with: .color(.black))
        context.fill(rect(30, 18, 8, 8), with: .color(.black))

        // Mouth
        context.fill(rect(18, 28, 16, 3), with: .color(.black))
    }
}
```

---

### Task 5: Create GhostMascot

**Files:**
- Create: `Notchy/UI/Components/Mascots/GhostMascot.swift`

- [ ] **Step 1: Create GhostMascot.swift**

```swift
//
//  GhostMascot.swift
//  Notchy
//
//  Pixel art ghost mascot drawing
//

import SwiftUI

enum GhostMascot {
    static func draw(in context: GraphicsContext, scale: CGFloat, color: Color, phase: Int) {
        // Float animation - whole body shifts vertically
        let floatOffsets: [CGFloat] = [-2, 0, 2, 0]
        let yOff = floatOffsets[phase % 4]

        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
            Path { p in
                p.addRect(CGRect(x: x, y: y + yOff, width: w, height: h))
            }.applying(CGAffineTransform(scaleX: scale, y: scale))
        }

        // Dome / body
        context.fill(rect(10, 2, 32, 34), with: .color(color))
        context.fill(rect(6, 10, 4, 22), with: .color(color))
        context.fill(rect(42, 10, 4, 22), with: .color(color))

        // Wavy bottom (3 scallops)
        context.fill(rect(6, 36, 10, 8), with: .color(color))
        context.fill(rect(22, 36, 8, 8), with: .color(color))
        context.fill(rect(36, 36, 10, 8), with: .color(color))

        // Eyes (hollow ovals)
        context.fill(rect(14, 16, 8, 12), with: .color(.black))
        context.fill(rect(30, 16, 8, 12), with: .color(.black))
        // Inner eye highlight
        context.fill(rect(16, 18, 4, 4), with: .color(color))
        context.fill(rect(32, 18, 4, 4), with: .color(color))
    }
}
```

---

### Task 6: Create CatMascot

**Files:**
- Create: `Notchy/UI/Components/Mascots/CatMascot.swift`

- [ ] **Step 1: Create CatMascot.swift**

```swift
//
//  CatMascot.swift
//  Notchy
//
//  Pixel art cat mascot drawing
//

import SwiftUI

enum CatMascot {
    static func draw(in context: GraphicsContext, scale: CGFloat, color: Color, phase: Int) {
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
            Path { p in
                p.addRect(CGRect(x: x, y: y, width: w, height: h))
            }.applying(CGAffineTransform(scaleX: scale, y: scale))
        }

        // Ears (triangular - stacked rects)
        context.fill(rect(8, 0, 4, 6), with: .color(color))
        context.fill(rect(6, 6, 8, 4), with: .color(color))
        context.fill(rect(36, 0, 4, 6), with: .color(color))
        context.fill(rect(34, 6, 8, 4), with: .color(color))

        // Head + body
        context.fill(rect(6, 10, 36, 28), with: .color(color))

        // Tail - sways side to side
        let tailOffsets: [CGFloat] = [0, 2, 4, 2]
        let tailX: CGFloat = 42 + tailOffsets[phase % 4]
        context.fill(rect(tailX, 22, 6, 14), with: .color(color))
        context.fill(rect(tailX + 2, 18, 4, 6), with: .color(color))

        // Legs
        context.fill(rect(10, 38, 8, 10), with: .color(color))
        context.fill(rect(30, 38, 8, 10), with: .color(color))

        // Eyes
        context.fill(rect(14, 18, 6, 6), with: .color(.black))
        context.fill(rect(28, 18, 6, 6), with: .color(.black))

        // Nose
        context.fill(rect(22, 26, 4, 3), with: .color(.black))

        // Whiskers
        let whiskerColor = color.opacity(0.5)
        context.fill(rect(2, 24, 6, 2), with: .color(whiskerColor))
        context.fill(rect(2, 28, 6, 2), with: .color(whiskerColor))
        context.fill(rect(40, 24, 6, 2), with: .color(whiskerColor))
        context.fill(rect(40, 28, 6, 2), with: .color(whiskerColor))
    }
}
```

---

### Task 7: Create SkullMascot

**Files:**
- Create: `Notchy/UI/Components/Mascots/SkullMascot.swift`

- [ ] **Step 1: Create SkullMascot.swift**

```swift
//
//  SkullMascot.swift
//  Notchy
//
//  Pixel art skull mascot drawing
//

import SwiftUI

enum SkullMascot {
    static func draw(in context: GraphicsContext, scale: CGFloat, color: Color, phase: Int) {
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
            Path { p in
                p.addRect(CGRect(x: x, y: y, width: w, height: h))
            }.applying(CGAffineTransform(scaleX: scale, y: scale))
        }

        // Cranium
        context.fill(rect(8, 0, 36, 30), with: .color(color))
        context.fill(rect(4, 6, 4, 18), with: .color(color))
        context.fill(rect(44, 6, 4, 18), with: .color(color))

        // Jaw - opens/closes
        let jawOffsets: [CGFloat] = [0, 2, 4, 2]
        let jawGap = jawOffsets[phase % 4]
        context.fill(rect(12, 30 + jawGap, 28, 10), with: .color(color))

        // Teeth
        context.fill(rect(16, 30 + jawGap, 4, 4), with: .color(.black))
        context.fill(rect(24, 30 + jawGap, 4, 4), with: .color(.black))
        context.fill(rect(32, 30 + jawGap, 4, 4), with: .color(.black))

        // Eye sockets
        context.fill(rect(12, 10, 10, 12), with: .color(.black))
        context.fill(rect(30, 10, 10, 12), with: .color(.black))

        // Nose
        context.fill(rect(22, 22, 8, 6), with: .color(.black))
    }
}
```

---

### Task 8: Create AlienMascot

**Files:**
- Create: `Notchy/UI/Components/Mascots/AlienMascot.swift`

- [ ] **Step 1: Create AlienMascot.swift**

```swift
//
//  AlienMascot.swift
//  Notchy
//
//  Pixel art alien mascot drawing
//

import SwiftUI

enum AlienMascot {
    static func draw(in context: GraphicsContext, scale: CGFloat, color: Color, phase: Int) {
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
            Path { p in
                p.addRect(CGRect(x: x, y: y, width: w, height: h))
            }.applying(CGAffineTransform(scaleX: scale, y: scale))
        }

        // Big head
        context.fill(rect(6, 0, 40, 28), with: .color(color))
        context.fill(rect(2, 6, 4, 16), with: .color(color))
        context.fill(rect(46, 6, 4, 16), with: .color(color))

        // Body
        context.fill(rect(16, 28, 20, 14), with: .color(color))

        // Legs
        context.fill(rect(12, 40, 8, 10), with: .color(color))
        context.fill(rect(32, 40, 8, 10), with: .color(color))

        // Eyes (large, black)
        context.fill(rect(10, 8, 14, 14), with: .color(.black))
        context.fill(rect(28, 8, 14, 14), with: .color(.black))

        // Pupils - blink animation (shrink vertically)
        let pupilHeights: [CGFloat] = [6, 4, 1, 4]
        let pupilH = pupilHeights[phase % 4]
        let pupilY: CGFloat = 12 + (6 - pupilH) / 2
        context.fill(rect(14, pupilY, 4, pupilH), with: .color(.white))
        context.fill(rect(34, pupilY, 4, pupilH), with: .color(.white))
    }
}
```

---

### Task 9: Create MascotIcon View

**Files:**
- Create: `Notchy/UI/Components/Mascots/MascotIcon.swift`

- [ ] **Step 1: Create MascotIcon.swift**

```swift
//
//  MascotIcon.swift
//  Notchy
//
//  Drop-in replacement for ClaudeCrabIcon — renders the user's chosen mascot
//

import Combine
import SwiftUI

struct MascotIcon: View {
    let size: CGFloat
    var animate: Bool = false
    var colorOverride: Color? = nil

    @State private var phase: Int = 0

    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    private var mascotType: MascotType {
        MascotType(rawValue: Settings.mascotType) ?? .crab
    }

    private var resolvedColor: Color {
        colorOverride ?? MascotColorPreset.resolve(Settings.mascotColor)
    }

    var body: some View {
        Canvas { context, _ in
            mascotType.draw(in: context, size: size, color: resolvedColor, animationPhase: phase)
        }
        .frame(width: size, height: size)
        .onReceive(timer) { _ in
            if animate {
                phase = (phase + 1) % 4
            }
        }
    }
}
```

- [ ] **Step 2: Build all mascot files**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodegen generate && xcodebuild build -project Notchy.xcodeproj -scheme Notchy -configuration Debug 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit all mascot files**

```bash
git add Notchy/UI/Components/Mascots/
git commit -m "feat: add MascotType enum, 6 mascot drawings, and MascotIcon view"
```

---

## Chunk 2: Integration + Settings UI

### Task 10: Replace ClaudeCrabIcon with MascotIcon

**Files:**
- Modify: `Notchy/UI/Views/NotchView.swift`
- Modify: `Notchy/UI/Views/NotchHeaderView.swift`
- Modify: `Notchy/UI/Views/ClosedStatePreview.swift`

- [ ] **Step 1: Replace in NotchView.swift**

Replace all 3 occurrences of `ClaudeCrabIcon` with `MascotIcon`:

| Line | Old | New |
|------|-----|-----|
| ~234 | `ClaudeCrabIcon(size: 14, animateLegs: isProcessing)` | `MascotIcon(size: 14, animate: isProcessing)` |
| ~246 | `ClaudeCrabIcon(size: 14)` | `MascotIcon(size: 14)` |
| ~306 | `ClaudeCrabIcon(size: 14)` | `MascotIcon(size: 14)` |

Also update `matchedGeometryEffect` IDs — they can stay as `"crab"` (just a string key).

- [ ] **Step 2: Replace in NotchHeaderView.swift opened header**

In the `openedHeaderContent` section (~line 306 of NotchView.swift), the `ClaudeCrabIcon(size: 14)` becomes `MascotIcon(size: 14)`.

- [ ] **Step 3: Delete ClaudeCrabIcon from NotchHeaderView.swift**

Remove the entire `ClaudeCrabIcon` struct (lines 11-118) from `NotchHeaderView.swift`. Keep `PermissionIndicatorIcon` and `ReadyForInputIndicatorIcon`.

- [ ] **Step 4: Replace in ClosedStatePreview.swift**

Replace all 6 occurrences of `ClaudeCrabIcon` with `MascotIcon`. Use find-and-replace:

| Line | Old | New |
|------|-----|-----|
| ~32 | `ClaudeCrabIcon(size: 14, animateLegs: false)` | `MascotIcon(size: 14)` |
| ~38 | `ClaudeCrabIcon(size: 14, animateLegs: true)` | `MascotIcon(size: 14, animate: true)` |
| ~81 | `ClaudeCrabIcon(size: 14, animateLegs: true)` | `MascotIcon(size: 14, animate: true)` |
| ~93 | `ClaudeCrabIcon(size: 14, animateLegs: true)` | `MascotIcon(size: 14, animate: true)` |
| ~109 | `ClaudeCrabIcon(size: 14, animateLegs: false)` | `MascotIcon(size: 14)` |
| ~141 | `ClaudeCrabIcon(size: size, animateLegs: animateLegs)` | `MascotIcon(size: size, animate: animateLegs)` |

- [ ] **Step 5: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodegen generate && xcodebuild build -project Notchy.xcodeproj -scheme Notchy -configuration Debug 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add Notchy/UI/Views/NotchView.swift Notchy/UI/Views/NotchHeaderView.swift Notchy/UI/Views/ClosedStatePreview.swift
git commit -m "refactor: replace ClaudeCrabIcon with MascotIcon everywhere"
```

---

### Task 11: Create MascotPickerRow Settings UI

**Files:**
- Create: `Notchy/UI/Components/MascotPickerRow.swift`

- [ ] **Step 1: Create MascotPickerRow.swift**

Follow the pattern of `SoundPickerRow` and `ScreenPickerRow` — collapsible section with selection UI.

```swift
//
//  MascotPickerRow.swift
//  Notchy
//
//  Mascot and color selection for settings menu
//

import SwiftUI

struct MascotPickerRow: View {
    @State private var isExpanded = false
    @State private var selectedType: String = Settings.mascotType
    @State private var selectedColor: String = Settings.mascotColor

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header row
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    MascotIcon(size: 12)
                        .frame(width: 16, height: 16)

                    Text("Mascot")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)

                    Spacer()

                    Text(currentMascotName)
                        .font(.system(size: 10))
                        .foregroundColor(TerminalColors.dim)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
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

            if isExpanded {
                mascotGrid
                colorRow
            }
        }
    }

    private var currentMascotName: String {
        (MascotType(rawValue: selectedType) ?? .crab).displayName
    }

    // MARK: - Mascot Grid (3x2)

    private var mascotGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
        ], spacing: 6) {
            ForEach(MascotType.allCases, id: \.rawValue) { mascot in
                mascotThumbnail(mascot)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    private func mascotThumbnail(_ mascot: MascotType) -> some View {
        Button {
            selectedType = mascot.rawValue
            Settings.mascotType = mascot.rawValue
        } label: {
            VStack(spacing: 2) {
                Canvas { context, _ in
                    mascot.draw(
                        in: context,
                        size: 24,
                        color: MascotColorPreset.resolve(selectedColor),
                        animationPhase: 0
                    )
                }
                .frame(width: 24, height: 24)

                Text(mascot.displayName)
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedType == mascot.rawValue
                        ? TerminalColors.backgroundHover
                        : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(selectedType == mascot.rawValue
                        ? TerminalColors.prompt.opacity(0.6)
                        : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Color Row

    private var colorRow: some View {
        HStack(spacing: 8) {
            ForEach(MascotColorPreset.allCases, id: \.rawValue) { preset in
                Button {
                    selectedColor = preset.rawValue
                    Settings.mascotColor = preset.rawValue
                } label: {
                    Circle()
                        .fill(preset.color)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: selectedColor == preset.rawValue ? 2 : 0)
                        )
                        .overlay(
                            selectedColor == preset.rawValue
                                ? Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.black.opacity(0.6))
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodegen generate && xcodebuild build -project Notchy.xcodeproj -scheme Notchy -configuration Debug 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Notchy/UI/Components/MascotPickerRow.swift
git commit -m "feat: add MascotPickerRow settings UI with character grid and color presets"
```

---

### Task 12: Add MascotPickerRow to NotchMenuView

**Files:**
- Modify: `Notchy/UI/Views/NotchMenuView.swift`

- [ ] **Step 1: Add MascotPickerRow between ScreenPickerRow and SoundPickerRow**

In `NotchMenuView.swift`, change the "Display & Sound" section:

```swift
// Old:
sectionHeader("Display & Sound")
ScreenPickerRow()
SoundPickerRow()

// New:
sectionHeader("Display & Sound")
ScreenPickerRow()
MascotPickerRow()
SoundPickerRow()
```

- [ ] **Step 2: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodegen generate && xcodebuild build -project Notchy.xcodeproj -scheme Notchy -configuration Debug 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Notchy/UI/Views/NotchMenuView.swift
git commit -m "feat: add mascot picker to settings menu"
```

---

### Task 13: Fix Permission Request Notification Sound

**Files:**
- Modify: `Notchy/UI/Views/NotchView.swift`

- [ ] **Step 1: Add sound to handlePendingSessionsChange**

In `NotchView.swift`, find `handlePendingSessionsChange` and add a sound before the notch opens:

```swift
// Old:
if !newPendingIds.isEmpty
    && viewModel.status == .closed
    && !TerminalVisibilityDetector.isTerminalVisibleOnCurrentSpace()
{
    viewModel.notchOpen(reason: .notification)
}

// New:
if !newPendingIds.isEmpty
    && viewModel.status == .closed
    && !TerminalVisibilityDetector.isTerminalVisibleOnCurrentSpace()
{
    NSSound(named: Settings.notificationSound)?.play()
    viewModel.notchOpen(reason: .notification)
}
```

- [ ] **Step 2: Build to verify**

Run: `cd /Users/ayo/Desktop/Notchi/Notchy && xcodebuild build -project Notchy.xcodeproj -scheme Notchy -configuration Debug 2>&1 | tail -3`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Notchy/UI/Views/NotchView.swift
git commit -m "fix: play notification sound on permission requests"
```

---

### Task 14: Final Build + Manual Test

- [ ] **Step 1: Full rebuild**

```bash
cd /Users/ayo/Desktop/Notchi/Notchy && xcodegen generate && xcodebuild build -project Notchy.xcodeproj -scheme Notchy -configuration Debug 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Launch and test mascot picker**

```bash
pkill -f "Notchy.app" 2>/dev/null; sleep 1 && open /Users/ayo/Library/Developer/Xcode/DerivedData/Notchy-airawsvzmfadjxfmxomluetugpak/Build/Products/Debug/Notchy.app
```

Manual test checklist:
- Open notch → Settings → Mascot section visible
- Tap each mascot in the 3×2 grid — preview updates
- Tap each color circle — mascot color changes
- Close notch → idle mascot shows in chosen character + color
- Start a Claude session → mascot animates
- Permission request → sound plays

- [ ] **Step 3: Screenshot to verify**

```bash
screencapture -R "0,0,1512,50" /tmp/notch-mascot-test.png
```
