# Notchy Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Notchy, a native macOS notch overlay app that monitors Claude Code CLI sessions — 1:1 clone of Claude Island.

**Architecture:** SwiftUI + AppKit hybrid. Unix socket IPC with a Python hook script. Actor-based session state with Combine publishers for reactive UI. Custom NSPanel anchored to the MacBook notch.

**Tech Stack:** Swift 6+, SwiftUI, AppKit, Combine, Swift actors, SPM (swift-markdown, Sparkle), Python 3

**Reference repo:** https://github.com/farouqaldori/claude-island — use this as the source of truth for implementation details. All file structures, algorithms, and UI behaviors should match.

---

## Chunk 1: Project Scaffolding & Data Models

### Task 1: Create Xcode Project

**Files:**
- Create: `Notchy/Notchy.xcodeproj/` (via xcodebuild)
- Create: `Notchy/Notchy/Info.plist`
- Create: `Notchy/Notchy/Resources/Notchy.entitlements`
- Create: `Notchy/Notchy/App/NotchyApp.swift`

- [ ] **Step 1: Generate Xcode project using `swift package init` and then convert, OR create manually**

Since we need a macOS App target (not a command-line tool), create the project structure manually. Use `xcodegen` or create the `.xcodeproj` via Xcode command line tools.

Alternative: Create a `Package.swift` first for the SPM dependencies, then create the Xcode project that references it.

Practical approach: Create the directory structure and a `Package.swift` for dependency resolution, then create the Xcode project using `xcodebuild` or a generation script.

```bash
mkdir -p Notchy/Notchy/{App,Core,Events,Models,Resources,Services/{Chat,Hooks,Session,Shared,State,Tmux,Update,Window},UI/{Components,Views,Window},Utilities}
mkdir -p Notchy/scripts
```

- [ ] **Step 2: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleName</key>
    <string>Notchy</string>
    <key>CFBundleIdentifier</key>
    <string>com.notchy.app</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.6</string>
    <key>SUFeedURL</key>
    <string>https://notchy.app/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>PLACEHOLDER</string>
</dict>
</plist>
```

- [ ] **Step 3: Create entitlements (no sandbox)**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

- [ ] **Step 4: Create NotchyApp.swift — minimal @main entry**

```swift
import SwiftUI

@main
struct NotchyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
```

- [ ] **Step 5: Create minimal AppDelegate.swift**

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure single instance
        let runningApps = NSWorkspace.shared.runningApplications
        let myBundleId = Bundle.main.bundleIdentifier ?? ""
        if runningApps.filter({ $0.bundleIdentifier == myBundleId }).count > 1 {
            NSApp.terminate(nil)
            return
        }
    }
}
```

- [ ] **Step 6: Create Package.swift for SPM dependencies**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotchyDeps",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.4.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.6.0"),
    ],
    targets: [
        .target(name: "NotchyDeps", dependencies: [
            .product(name: "Markdown", package: "swift-markdown"),
            .product(name: "Sparkle", package: "Sparkle"),
        ]),
    ]
)
```

- [ ] **Step 7: Verify project builds**

```bash
cd Notchy && swift build 2>&1 | tail -5
```

Expected: Build succeeds (or we switch to xcodebuild once .xcodeproj is created)

- [ ] **Step 8: Commit**

```bash
git add -A && git commit -m "feat: scaffold Notchy project with SPM dependencies"
```

### Task 2: Data Models

**Files:**
- Create: `Notchy/Notchy/Models/SessionPhase.swift`
- Create: `Notchy/Notchy/Models/SessionEvent.swift`
- Create: `Notchy/Notchy/Models/SessionState.swift`
- Create: `Notchy/Notchy/Models/ChatMessage.swift`
- Create: `Notchy/Notchy/Models/TmuxTarget.swift`
- Create: `Notchy/Notchy/Models/ToolResultData.swift`

Reference: `ClaudeIsland/Models/` in the original repo for exact structures.

- [ ] **Step 1: Create SessionPhase.swift — state machine enum**

```swift
import Foundation

enum SessionPhase: String, Codable, Sendable {
    case idle
    case processing
    case waitingForInput
    case waitingForApproval
    case compacting
    case ended

    func canTransition(to next: SessionPhase) -> Bool {
        switch (self, next) {
        case (.idle, .processing),
             (.processing, .waitingForInput),
             (.processing, .waitingForApproval),
             (.processing, .compacting),
             (.processing, .idle),        // Stop interrupt
             (.processing, .ended),       // Stop end
             (.waitingForInput, .processing),
             (.waitingForApproval, .processing),
             (.compacting, .processing),
             (.idle, .ended),             // timeout/archive
             (_, .ended),                 // sessionGone
             (_, .idle):                  // error recovery
            return true
        default:
            return false
        }
    }
}
```

- [ ] **Step 2: Create a Sendable JSONValue type**

`[String: Any]` does not conform to `Sendable`. Create a recursive enum for type-safe JSON handling:

```swift
// Put this at the top of SessionEvent.swift or in a separate JSONValue.swift
enum JSONValue: Sendable, Codable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])
}
```

- [ ] **Step 3: Create SessionEvent.swift — unified event enum**

```swift
import Foundation

enum SessionEvent: Sendable {
    case userPromptSubmit(sessionId: String, prompt: String)
    case preToolUse(sessionId: String, tool: String, input: [String: JSONValue])
    case postToolUse(sessionId: String, tool: String, output: String)
    case permissionRequest(sessionId: String, tool: String, input: [String: JSONValue], requestId: String)
    case permissionResponse(sessionId: String, requestId: String, decision: PermissionDecision)
    case notification(sessionId: String, title: String, body: String)
    case stop(sessionId: String, reason: StopReason)
    case preCompact(sessionId: String)
    case subagentStop(sessionId: String, subagentId: String)
    case sessionGone(sessionId: String)
}

enum PermissionDecision: String, Sendable {
    case allow
    case deny
}

enum StopReason: String, Sendable {
    case end
    case interrupt
}
```

- [ ] **Step 4: Create SessionState.swift**

Reference original `ClaudeIsland/Models/SessionState.swift`. Key structures:

```swift
struct SessionState: Sendable, Identifiable {
    let id: String                    // session UUID
    var phase: SessionPhase = .idle
    var projectName: String = ""
    var cwd: String = ""
    var tmuxTarget: TmuxTarget?
    var activeTools: [ToolTracker] = []
    var pendingPermission: PendingPermission?
    var lastActivity: Date = Date()
}

struct ToolTracker: Sendable, Identifiable {
    let id: String
    let tool: String
    let input: [String: JSONValue]
    var status: ToolStatus = .running
    var output: String?
}

enum ToolStatus: Sendable { case running, completed, failed }

struct PendingPermission: Sendable {
    let requestId: String
    let tool: String
    let input: [String: JSONValue]
}

struct SubagentState: Sendable {
    let id: String
    var phase: SessionPhase = .processing
}
```

- [ ] **Step 5: Create ChatMessage.swift**

```swift
import Foundation

struct ChatMessage: Sendable, Identifiable {
    let id: String
    let role: ChatRole
    let blocks: [MessageBlock]
    let timestamp: Date
}

enum ChatRole: String, Sendable { case user, assistant, system }

enum MessageBlock: Sendable, Identifiable {
    case text(id: String, content: String)
    case thinking(id: String, content: String)
    case toolUse(ToolUseBlock)
    case toolResult(id: String, toolUseId: String, content: String)
}

struct ToolUseBlock: Sendable, Identifiable {
    let id: String
    let tool: String
    let input: [String: JSONValue]
    var status: ToolStatus = .running
    var result: ToolResultData?
}
```

- [ ] **Step 6: Create TmuxTarget.swift**

```swift
import Foundation

struct TmuxTarget: Sendable, Equatable {
    let session: String
    let window: String
    let pane: String

    var targetString: String { "\(session):\(window).\(pane)" }
}
```

- [ ] **Step 7: Create ToolResultData.swift**

Reference original `ClaudeIsland/Models/ToolResultData.swift`. Key structure:

```swift
enum ToolResultData: Sendable {
    case read(ReadResult)
    case edit(EditResult)
    case write(WriteResult)
    case bash(BashResult)
    case grep(GrepResult)
    case glob(GlobResult)
    case webFetch(WebFetchResult)
    case webSearch(WebSearchResult)
    case task(TaskResult)
    case todoWrite(TodoWriteResult)
    case askUserQuestion(AskUserQuestionResult)
    case mcp(MCPResult)
    case generic(GenericResult)
}

struct ReadResult: Sendable { let filePath: String; let content: String; let lineCount: Int }
struct EditResult: Sendable { let filePath: String; let diff: String; let oldContent: String; let newContent: String }
struct WriteResult: Sendable { let filePath: String; let content: String }
struct BashResult: Sendable { let command: String; let output: String; let exitCode: Int }
struct GrepResult: Sendable { let pattern: String; let matches: [GrepMatch] }
struct GrepMatch: Sendable { let file: String; let line: Int; let content: String }
struct GlobResult: Sendable { let pattern: String; let files: [String] }
struct WebFetchResult: Sendable { let url: String; let content: String }
struct WebSearchResult: Sendable { let query: String; let results: [SearchResult] }
struct SearchResult: Sendable { let title: String; let url: String; let snippet: String }
struct TaskResult: Sendable { let status: String; let description: String }
struct TodoWriteResult: Sendable { let items: [String] }
struct AskUserQuestionResult: Sendable { let question: String }
struct MCPResult: Sendable { let server: String; let tool: String; let output: String }
struct GenericResult: Sendable { let tool: String; let output: String }
```

- [ ] **Step 9: Verify models compile**

```bash
xcodebuild build -scheme Notchy 2>&1 | tail -5
```

- [ ] **Step 10: Commit**

```bash
git add Notchy/Notchy/Models/ && git commit -m "feat: add data models — SessionPhase, SessionEvent, SessionState, ChatMessage, TmuxTarget, ToolResultData"
```

---

## Chunk 2: Core Infrastructure & Utilities

### Task 3: NSScreen Extensions & Settings

**Files:**
- Create: `Notchy/Notchy/Core/Ext+NSScreen.swift`
- Create: `Notchy/Notchy/Core/Settings.swift`
- Create: `Notchy/Notchy/Core/ScreenSelector.swift`
- Create: `Notchy/Notchy/Core/SoundSelector.swift`

- [ ] **Step 1: Create Ext+NSScreen.swift**

Reference original `ClaudeIsland/Core/Ext+NSScreen.swift`. Key properties:
- `notchSize` — returns the size of the physical notch area
- `hasPhysicalNotch` — detects if the display has a notch
- `isBuiltinDisplay` — checks if the display is the built-in MacBook display

- [ ] **Step 2: Create Settings.swift — UserDefaults wrapper with property wrapper**

```swift
import Foundation

@propertyWrapper
struct UserDefaultsBacked<T> {
    let key: String
    let defaultValue: T
    var wrappedValue: T {
        get { UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

enum Settings {
    @UserDefaultsBacked(key: "selectedScreenId", defaultValue: nil)
    static var selectedScreenId: String?

    @UserDefaultsBacked(key: "notificationSound", defaultValue: "Pop")
    static var notificationSound: String

    @UserDefaultsBacked(key: "launchAtLogin", defaultValue: false)
    static var launchAtLogin: Bool
}
```

- [ ] **Step 3: Create ScreenSelector.swift**

Multi-display support: auto-detects built-in display with notch, allows manual override. Reference original.

- [ ] **Step 4: Create SoundSelector.swift**

Sound picker state management. List of 15 notification sound names.

- [ ] **Step 5: Commit**

```bash
git add Notchy/Notchy/Core/ && git commit -m "feat: add core infrastructure — NSScreen extensions, Settings, ScreenSelector, SoundSelector"
```

### Task 4: Event Monitors

**Files:**
- Create: `Notchy/Notchy/Events/EventMonitor.swift`
- Create: `Notchy/Notchy/Events/EventMonitors.swift`

- [ ] **Step 1: Create EventMonitor.swift — NSEvent wrapper**

```swift
import AppKit

class EventMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent) -> Void

    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> Void) {
        self.mask = mask
        self.handler = handler
    }

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handler(event)
            return event
        }
    }

    func stop() {
        if let global = globalMonitor { NSEvent.removeMonitor(global) }
        if let local = localMonitor { NSEvent.removeMonitor(local) }
        globalMonitor = nil
        localMonitor = nil
    }
}
```

- [ ] **Step 2: Create EventMonitors.swift — singleton with Combine publishers**

Mouse location publisher and mouse down publisher. Reference original.

- [ ] **Step 3: Commit**

```bash
git add Notchy/Notchy/Events/ && git commit -m "feat: add event monitors for global/local NSEvent tracking"
```

### Task 5: Shared Services

**Files:**
- Create: `Notchy/Notchy/Services/Shared/ProcessExecutor.swift`
- Create: `Notchy/Notchy/Services/Shared/ProcessTreeBuilder.swift`
- Create: `Notchy/Notchy/Services/Shared/TerminalAppRegistry.swift`

- [ ] **Step 1: Create ProcessExecutor.swift — async shell command execution**

```swift
import Foundation

enum ProcessExecutor {
    static func execute(_ command: String, arguments: [String] = []) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: command)
            process.arguments = arguments
            process.standardOutput = pipe
            process.standardError = pipe
            process.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                continuation.resume(returning: output)
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
```

- [ ] **Step 2: Create ProcessTreeBuilder.swift**

Builds process tree by calling `ps aux`, parses output, finds `claude` processes. Reference original for exact parsing logic.

- [ ] **Step 3: Create TerminalAppRegistry.swift**

Detects terminal emulator (Terminal.app, iTerm2, Alacritty, Kitty, WezTerm, etc.) from running applications.

- [ ] **Step 4: Commit**

```bash
git add Notchy/Notchy/Services/Shared/ && git commit -m "feat: add shared services — ProcessExecutor, ProcessTreeBuilder, TerminalAppRegistry"
```

### Task 6: Utilities

**Files:**
- Create: `Notchy/Notchy/Utilities/MCPToolFormatter.swift`
- Create: `Notchy/Notchy/Utilities/SessionPhaseHelpers.swift`
- Create: `Notchy/Notchy/Utilities/TerminalVisibilityDetector.swift`

- [ ] **Step 1: Create MCPToolFormatter.swift**

Formats MCP tool names (e.g., `mcp__server__tool` → `server: tool`). Reference original.

- [ ] **Step 2: Create SessionPhaseHelpers.swift**

Utility methods for SessionPhase (display strings, colors, icons). Reference original.

- [ ] **Step 3: Create TerminalVisibilityDetector.swift**

Detects if the terminal running a Claude session is currently visible on screen.

- [ ] **Step 4: Commit**

```bash
git add Notchy/Notchy/Utilities/ && git commit -m "feat: add utilities — MCPToolFormatter, SessionPhaseHelpers, TerminalVisibilityDetector"
```

---

## Chunk 3: Window System

### Task 7: Custom NSPanel & Window Infrastructure

**Files:**
- Create: `Notchy/Notchy/UI/Window/NotchWindow.swift`
- Create: `Notchy/Notchy/UI/Window/NotchViewController.swift`
- Create: `Notchy/Notchy/UI/Window/NotchWindowController.swift`
- Create: `Notchy/Notchy/App/WindowManager.swift`
- Create: `Notchy/Notchy/App/ScreenObserver.swift`

- [ ] **Step 1: Create NotchWindow.swift — custom NSPanel**

```swift
import AppKit

class NotchWindow: NSPanel {
    override init(contentRect: NSRect, styleMask: NSWindow.StyleMask, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        self.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isMovable = false
        self.isMovableByWindowBackground = false
    }
}
```

Reference original for full implementation including `canBecomeKey`, `canBecomeMain` overrides.

- [ ] **Step 2: Create NotchViewController.swift — AppKit hosting with click-through hit-testing**

NSHostingController that hosts the SwiftUI NotchView. Implements custom `hitTest` for click-through behavior when the notch is closed.

Reference original for the hit-test logic.

- [ ] **Step 3: Create NotchWindowController.swift — positioning & boot animation**

Handles:
- Window positioning relative to the notch
- Boot animation (brief open then close on launch)
- Focus management

Reference original.

- [ ] **Step 4: Create WindowManager.swift — window lifecycle**

Creates and manages the NotchWindow. Responds to screen changes. Reference original.

- [ ] **Step 5: Create ScreenObserver.swift — display change notifications**

Observes `NSApplication.didChangeScreenParametersNotification` to handle display connect/disconnect. Reference original.

- [ ] **Step 6: Verify build**

```bash
xcodebuild build -scheme Notchy 2>&1 | tail -5
```

- [ ] **Step 7: Commit**

```bash
git add Notchy/Notchy/UI/Window/ Notchy/Notchy/App/WindowManager.swift Notchy/Notchy/App/ScreenObserver.swift && git commit -m "feat: add window system — NotchWindow NSPanel, hit-testing, positioning, screen observer"
```

---

## Chunk 4: Notch UI Components & Views

### Task 8: UI Components

**Files:**
- Create: `Notchy/Notchy/UI/Components/TerminalColors.swift`
- Create: `Notchy/Notchy/UI/Components/NotchShape.swift`
- Create: `Notchy/Notchy/UI/Components/StatusIcons.swift`
- Create: `Notchy/Notchy/UI/Components/ProcessingSpinner.swift`
- Create: `Notchy/Notchy/UI/Components/ActionButton.swift`

- [ ] **Step 1: Create TerminalColors.swift — color palette**

```swift
import SwiftUI

enum TerminalColors {
    static let green = Color(red: 0.31, green: 0.98, blue: 0.48)       // #50fa7b
    static let amber = Color(red: 0.94, green: 0.75, blue: 0.25)       // #f0c040
    static let red = Color(red: 1.0, green: 0.33, blue: 0.33)          // #ff5555
    static let cyan = Color(red: 0.55, green: 0.91, blue: 0.99)        // #8be9fd
    static let claudeOrange = Color(red: 0.85, green: 0.47, blue: 0.34) // #d97857
    static let background = Color.black
    static let text = Color.white
}
```

- [ ] **Step 2: Create NotchShape.swift — custom Shape with quadratic Bezier curves**

Reference original `ClaudeIsland/UI/Components/NotchShape.swift` for exact curve control points. This is critical for matching the physical notch appearance.

- [ ] **Step 3: Create StatusIcons.swift — pixel-art Canvas icons**

Permission indicator (amber), ready indicator (green checkmark), error indicator (red). Drawn via SwiftUI Canvas. Reference original.

- [ ] **Step 4: Create ProcessingSpinner.swift — animated Unicode glyphs**

6 rotating Unicode symbols in Claude Orange (#d97857). Reference original for the exact glyphs and rotation timing.

- [ ] **Step 5: Create ActionButton.swift — reusable button with hover effects**

Reference original for hover state styling.

- [ ] **Step 6: Commit**

```bash
git add Notchy/Notchy/UI/Components/ && git commit -m "feat: add UI components — colors, notch shape, status icons, spinner, action button"
```

### Task 9: Core Notch Views

**Files:**
- Create: `Notchy/Notchy/Core/NotchGeometry.swift`
- Create: `Notchy/Notchy/Core/NotchViewModel.swift`
- Create: `Notchy/Notchy/Core/NotchActivityCoordinator.swift`
- Create: `Notchy/Notchy/UI/Views/NotchHeaderView.swift`
- Create: `Notchy/Notchy/UI/Views/NotchView.swift`

- [ ] **Step 1: Create NotchGeometry.swift — hit-testing & coordinate transforms**

Panel sizing calculations, coordinate transforms between screen and notch space. Reference original.

- [ ] **Step 2a: Create NotchViewModel.swift — observable properties and state enum**

```swift
import SwiftUI
import Combine

enum NotchState { case closed, popping, opened }
enum NotchPage { case instances, chat(sessionId: String), menu }

@MainActor
class NotchViewModel: ObservableObject {
    @Published var state: NotchState = .closed
    @Published var currentPage: NotchPage = .instances
    @Published var isHovering = false
    @Published var panelSize: CGSize = .zero
    // ... add remaining properties per original
}
```

- [ ] **Step 2b: NotchViewModel — hover detection logic**

Add hover detection with 1-second delay using Combine timer. Subscribe to EventMonitors mouse location publisher. Reference original for debounce/threshold logic.

- [ ] **Step 2c: NotchViewModel — open/close/pop state transitions**

Implement `open()`, `close()`, `pop(reason:)` methods with spring animations (response: 0.42, damping: 0.45). Handle click-outside-to-close. Reference original.

- [ ] **Step 2d: NotchViewModel — chat persistence and session binding**

Track which session's chat is open. Persist across close/reopen. Bind to ClaudeSessionMonitor for live updates. Reference original.

- [ ] **Step 3: Create NotchActivityCoordinator.swift**

Singleton that coordinates expanding activity animations across sessions.

- [ ] **Step 4: Create NotchHeaderView.swift — crab icon with indicators**

Animated crab icon (walking legs during processing), amber/green pixel-art indicators. Reference original for the crab animation implementation.

- [ ] **Step 5: Create NotchView.swift — main container view**

Switches between closed/open/popping states. Routes to instances list, chat, or settings. Uses spring animations (response: 0.42, damping: 0.45). Reference original.

- [ ] **Step 6: Verify build and run — should show a black notch overlay**

```bash
xcodebuild build -scheme Notchy && open build/Debug/Notchy.app
```

- [ ] **Step 7: Commit**

```bash
git add Notchy/Notchy/Core/Notch* Notchy/Notchy/UI/Views/Notch* && git commit -m "feat: add notch views — NotchView, NotchHeaderView, geometry, view model, activity coordinator"
```

---

## Chunk 5: Hook System

### Task 10: Python Hook Script

**Files:**
- Create: `Notchy/Notchy/Resources/notchy-state.py`

- [ ] **Step 1: Create notchy-state.py**

Reference original `ClaudeIsland/Resources/claude-island-state.py`. Key changes:
- Rename all references from "claude-island" to "notchy"
- Socket path: `os.path.join(os.environ.get('TMPDIR', '/tmp'), 'notchy.sock')`
- Add `NOTCHY_VERSION = "1.0.0"` constant
- Add `protocol_version: 1` to all messages

The script:
1. Reads hook event from stdin (Claude Code passes JSON)
2. Connects to `$TMPDIR/notchy.sock`
3. Sends JSON payload
4. For PermissionRequest: blocks waiting for response
5. On connection refused: exits 0
6. On unexpected error: exits 1, logs to stderr

- [ ] **Step 2: Verify script syntax**

```bash
python3 -c "import ast; ast.parse(open('Notchy/Notchy/Resources/notchy-state.py').read()); print('OK')"
```

- [ ] **Step 3: Commit**

```bash
git add Notchy/Notchy/Resources/notchy-state.py && git commit -m "feat: add Python hook script for Claude Code integration"
```

### Task 11: Hook Services

**Files:**
- Create: `Notchy/Notchy/Services/Hooks/HookInstaller.swift`
- Create: `Notchy/Notchy/Services/Hooks/HookSocketServer.swift`

- [ ] **Step 1: Create HookInstaller.swift**

Reference original `ClaudeIsland/Services/Hooks/HookInstaller.swift`. Key responsibilities:
- Copy bundled `notchy-state.py` to `~/.claude/hooks/`
- Read `~/.claude/settings.json`
- Merge hook entries with `"source": "notchy"` field
- Write back, preserving existing non-Notchy hooks
- Version check: compare `NOTCHY_VERSION` in installed vs bundled script

- [ ] **Step 2: Create HookSocketServer.swift**

Reference original `ClaudeIsland/Services/Hooks/HookSocketServer.swift`. Key responsibilities:
- Unix domain socket at `$TMPDIR/notchy.sock`
- Unlink stale socket on start
- Accept connections, read JSON payloads
- Validate `protocol_version` field — reject messages with unsupported versions (log warning)
- Parse into SessionEvent and forward to SessionStore
- For PermissionRequest: hold connection open, wait for response (30s timeout)
- Send back permission response JSON
- Unlink socket on quit

- [ ] **Step 3: Verify build**

```bash
xcodebuild build -scheme Notchy 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add Notchy/Notchy/Services/Hooks/ && git commit -m "feat: add hook services — HookInstaller, HookSocketServer"
```

---

## Chunk 6: Session Engine

### Task 12: Session State Management

**Files:**
- Create: `Notchy/Notchy/Services/State/SessionStore.swift`
- Create: `Notchy/Notchy/Services/State/ToolEventProcessor.swift`
- Create: `Notchy/Notchy/Services/State/FileSyncScheduler.swift`

- [ ] **Step 1: Create SessionStore.swift — actor-based central state**

Reference original `ClaudeIsland/Services/State/SessionStore.swift`. This is the single source of truth:
- Swift actor for thread safety
- `process(event: SessionEvent)` method handles all state mutations
- Publishes session state changes via Combine
- Maintains dictionary of `[String: SessionState]` keyed by session ID

- [ ] **Step 2: Create ToolEventProcessor.swift**

Processes PreToolUse and PostToolUse events. Manages ToolTracker state (running, completed, failed). Handles subagent events. Reference original.

- [ ] **Step 3: Create FileSyncScheduler.swift**

Debounced file sync (100ms) for writing state back to JSONL files. Reference original.

- [ ] **Step 4: Commit**

```bash
git add Notchy/Notchy/Services/State/ && git commit -m "feat: add session state management — SessionStore actor, ToolEventProcessor, FileSyncScheduler"
```

### Task 13: Session Monitoring Services

**Files:**
- Create: `Notchy/Notchy/Services/Session/ConversationParser.swift`
- Create: `Notchy/Notchy/Services/Session/AgentFileWatcher.swift`
- Create: `Notchy/Notchy/Services/Session/ClaudeSessionMonitor.swift`
- Create: `Notchy/Notchy/Services/Session/JSONLInterruptWatcher.swift`

- [ ] **Step 1a: Create ConversationParser.swift — basic JSONL line parsing**

Parse individual JSONL lines into ChatMessage objects. Handle user/assistant roles, text blocks, thinking blocks. Skip malformed lines with logged warning. Reference original for JSON field names.

- [ ] **Step 1b: ConversationParser — tool result extraction**

Parse tool_use and tool_result blocks. Map tool names to ToolResultData types (Read, Edit, Write, Bash, etc.). Unknown tools → GenericResult. Reference original for the exact field mapping per tool type.

- [ ] **Step 1c: ConversationParser — incremental parsing with file offset tracking**

Track byte offset into JSONL file. On re-parse, seek to last offset and only parse new lines. Full parse resets offset to 0. Reference original for the FileHandle seeking logic.

- [ ] **Step 2: Create AgentFileWatcher.swift**

Uses `DispatchSource.makeFileSystemObjectSource` to watch JSONL files for changes. Triggers incremental parsing. Reference original.

- [ ] **Step 3: Create ClaudeSessionMonitor.swift — MainActor UI binding**

Observable object on MainActor. Bridges between SessionStore (actor) and SwiftUI views. Handles approve/deny actions. Starts a 5-second polling timer that calls ProcessTreeBuilder to discover/remove Claude sessions. Fires `sessionGone` events when processes disappear. Reference original.

- [ ] **Step 4: Create JSONLInterruptWatcher.swift**

Detects when a session is interrupted (e.g., user hits Ctrl+C). Reference original.

- [ ] **Step 5: Commit**

```bash
git add Notchy/Notchy/Services/Session/ && git commit -m "feat: add session monitoring — ConversationParser, AgentFileWatcher, ClaudeSessionMonitor, JSONLInterruptWatcher"
```

### Task 14: Chat History Manager

**Files:**
- Create: `Notchy/Notchy/Services/Chat/ChatHistoryManager.swift`

- [ ] **Step 1: Create ChatHistoryManager.swift**

Observable history manager. Coordinates with ConversationParser for JSONL sync. Provides chat messages to ChatView. Reference original.

- [ ] **Step 2: Commit**

```bash
git add Notchy/Notchy/Services/Chat/ && git commit -m "feat: add ChatHistoryManager for conversation history"
```

---

## Chunk 7: Tmux Integration

### Task 15: Tmux Services

**Files:**
- Create: `Notchy/Notchy/Services/Tmux/TmuxPathFinder.swift`
- Create: `Notchy/Notchy/Services/Tmux/TmuxController.swift`
- Create: `Notchy/Notchy/Services/Tmux/TmuxSessionMatcher.swift`
- Create: `Notchy/Notchy/Services/Tmux/TmuxTargetFinder.swift`
- Create: `Notchy/Notchy/Services/Tmux/ToolApprovalHandler.swift`

- [ ] **Step 1: Create TmuxPathFinder.swift**

Locates the tmux binary. Checks `/opt/homebrew/bin/tmux`, `/usr/local/bin/tmux`, and `which tmux`. Reference original.

- [ ] **Step 2: Create TmuxController.swift**

Queries tmux for session list, window list, pane info. Uses ProcessExecutor to call tmux commands. Reference original.

- [ ] **Step 3: Create TmuxSessionMatcher.swift**

Matches Claude Code sessions to tmux panes by walking the process tree from the Claude PID up to find a tmux server process, then mapping to the pane. Reference original.

- [ ] **Step 4: Create TmuxTargetFinder.swift**

Finds the tmux target (session:window.pane) for a given TTY. Reference original.

- [ ] **Step 5: Create ToolApprovalHandler.swift**

Two approval paths:
1. **Socket-based (primary):** HookSocketServer sends the permission response JSON back to the waiting Python hook. This is the main path for PermissionRequest events.
2. **tmux send-keys (fallback):** For non-hook approval flows or when the socket response path fails, sends keystrokes ("y"/"n" + Enter) to the tmux pane.

ToolApprovalHandler coordinates both: first tries socket response via HookSocketServer, falls back to tmux send-keys. Reference original.

- [ ] **Step 6: Commit**

```bash
git add Notchy/Notchy/Services/Tmux/ && git commit -m "feat: add tmux integration — path finder, controller, session matcher, target finder, approval handler"
```

---

## Chunk 8: Window Services

### Task 16: Window Discovery & Focus

**Files:**
- Create: `Notchy/Notchy/Services/Window/WindowFinder.swift`
- Create: `Notchy/Notchy/Services/Window/WindowFocuser.swift`
- Create: `Notchy/Notchy/Services/Window/YabaiController.swift`

- [ ] **Step 1: Create WindowFinder.swift**

Discovers windows using Accessibility API (AXUIElement). Finds terminal windows by PID. Reference original.

- [ ] **Step 2: Create WindowFocuser.swift**

Focuses a window by PID. Falls back to `NSRunningApplication.activate()` when yabai is not available. Reference original.

- [ ] **Step 3: Create YabaiController.swift**

Optional yabai integration. Calls `yabai -m window --focus <id>`. Detects if yabai is installed. Reference original.

- [ ] **Step 4: Commit**

```bash
git add Notchy/Notchy/Services/Window/ && git commit -m "feat: add window services — WindowFinder, WindowFocuser, YabaiController"
```

---

## Chunk 9: Chat & Instances UI

### Task 17: Markdown Renderer

**Files:**
- Create: `Notchy/Notchy/UI/Components/MarkdownRenderer.swift`

- [ ] **Step 1: Create MarkdownRenderer.swift**

Uses swift-markdown library to parse and render markdown content. Includes document cache for performance. Reference original for the rendering pipeline and cache implementation.

- [ ] **Step 2: Commit**

```bash
git add Notchy/Notchy/UI/Components/MarkdownRenderer.swift && git commit -m "feat: add markdown renderer with document cache"
```

### Task 18: Tool Result Views

**Files:**
- Create: `Notchy/Notchy/UI/Views/ToolResultViews.swift`

- [ ] **Step 1a: Create ToolResultViews.swift — file I/O views (Read, Edit, Write)**

- ReadResultView: file path header, monospaced content with line numbers, scrollable
- EditResultView: inline diff view with red/green highlighting (LCS-based diff from ConversationParser)
- WriteResultView: file path header, content preview

Reference original for exact layouts.

- [ ] **Step 1b: ToolResultViews — execution views (Bash, Grep, Glob)**

- BashResultView: command header, monospaced output, exit code badge (green 0, red non-zero)
- GrepResultView: pattern header, file:line matches grouped by file
- GlobResultView: pattern header, file list

- [ ] **Step 1c: ToolResultViews — remaining views (WebFetch, WebSearch, Task, Todo, AskUser, MCP, Generic)**

- WebFetchResultView: URL header, truncated content preview
- WebSearchResultView: query header, results list with title/URL/snippet
- TaskResultView: status badge + description
- TodoWriteResultView: checklist items
- AskUserQuestionResultView: question text + "answer in terminal" hint
- MCPToolResultView: server:tool header, output
- GenericToolResultView: tool name header, raw output (fallback)

- [ ] **Step 2: Commit**

```bash
git add Notchy/Notchy/UI/Views/ToolResultViews.swift && git commit -m "feat: add 14+ specialized tool result renderers"
```

### Task 19: Chat View

**Files:**
- Create: `Notchy/Notchy/UI/Views/ChatView.swift`

- [ ] **Step 1a: Create ChatView.swift — message list with inverted ScrollView**

Inverted ScrollView (rotated 180°) for bottom-anchored chat. User messages right-aligned in rounded bubbles (dark gray background, white text). Assistant messages left-aligned with white dot prefix. Tool calls show colored status dots (pulsing animation for running/waiting, solid for complete). Expandable tool results using ToolResultViews. Auto-scroll pause on user scroll-up, resume on scroll-to-bottom. "N new messages" floating capsule indicator when scrolled up. Reference original for the rotation trick and scroll detection.

- [ ] **Step 1b: ChatView — input bar and message sending**

TextField at bottom for typing messages. On submit, sends text to the session's tmux pane via TmuxController send-keys. Show/hide based on whether session has a tmux target.

- [ ] **Step 1c: ChatView — approval bar and interactive prompt bar**

Approval bar: Allow (green) / Deny (red) capsule buttons for pending PermissionRequest. Shows tool name and input summary. Interactive prompt bar for AskUserQuestion tools — shows question text with "answer in terminal" redirect.

- [ ] **Step 2: Commit**

```bash
git add Notchy/Notchy/UI/Views/ChatView.swift && git commit -m "feat: add ChatView with full conversation display, input bar, and approval controls"
```

### Task 20: Instances View

**Files:**
- Create: `Notchy/Notchy/UI/Views/ClaudeInstancesView.swift`

- [ ] **Step 1a: Create ClaudeInstancesView.swift — session list with sorting and status**

List of active sessions sorted by priority: waitingForApproval > waitingForInput > processing > idle > ended. Each row shows: project name (extracted from CWD), colored status dot (green=ready, amber=approval, cyan=processing), phase label.

- [ ] **Step 1b: ClaudeInstancesView — action buttons with animations**

Per-session action buttons:
- Allow/Deny: inline capsule buttons, shown only when waitingForApproval. Staggered spring animation on appearance.
- Chat: opens ChatView for that session
- Focus: focuses terminal window via WindowFocuser (hidden when no tmux target)
- Archive: removes ended/idle sessions from the list

- [ ] **Step 2: Commit**

```bash
git add Notchy/Notchy/UI/Views/ClaudeInstancesView.swift && git commit -m "feat: add ClaudeInstancesView — session list with status and actions"
```

---

## Chunk 10: Settings UI & Sparkle

### Task 21: Settings Components

**Files:**
- Create: `Notchy/Notchy/UI/Components/ScreenPickerRow.swift`
- Create: `Notchy/Notchy/UI/Components/SoundPickerRow.swift`

- [ ] **Step 1: Create ScreenPickerRow.swift**

Display selection UI. Shows "Auto" or manual display name. Reference original.

- [ ] **Step 2: Create SoundPickerRow.swift**

Sound selection UI. Dropdown with 15 macOS notification sounds. Plays preview on selection. Reference original.

- [ ] **Step 3: Commit**

```bash
git add Notchy/Notchy/UI/Components/Screen* Notchy/Notchy/UI/Components/Sound* && git commit -m "feat: add screen picker and sound picker settings components"
```

### Task 22: Settings Menu View

**Files:**
- Create: `Notchy/Notchy/UI/Views/NotchMenuView.swift`

- [ ] **Step 1: Create NotchMenuView.swift**

Settings panel with all controls. Reference original. Sections:
- Screen picker (ScreenPickerRow)
- Sound picker (SoundPickerRow)
- Launch at login toggle (ServiceManagement)
- Hook installation status + reinstall button
- Accessibility permission check (`AXIsProcessTrusted()`) with "Grant" button that opens System Settings
- tmux detection status — shows "tmux required" hint when tmux is not installed
- Sparkle update management (progress via NotchUserDriver's published state)
- GitHub link
- Quit button

- [ ] **Step 2: Commit**

```bash
git add Notchy/Notchy/UI/Views/NotchMenuView.swift && git commit -m "feat: add NotchMenuView settings panel"
```

### Task 23: Sparkle Integration

**Files:**
- Create: `Notchy/Notchy/Services/Update/NotchUserDriver.swift`

- [ ] **Step 1: Create NotchUserDriver.swift — Sparkle update UI driver**

Implements `SPUUserDriver` protocol for Sparkle. Shows update progress in the settings menu. Reference original.

- [ ] **Step 2: Commit**

```bash
git add Notchy/Notchy/Services/Update/ && git commit -m "feat: add Sparkle auto-update integration"
```

---

## Chunk 11: App Integration & Scripts

### Task 24: Wire Up AppDelegate

**Files:**
- Modify: `Notchy/Notchy/App/AppDelegate.swift`

- [ ] **Step 1: Complete AppDelegate.swift**

First verify a clean build of all prior chunks compiles together.

Wire up all services on launch:
1. Check `AXIsProcessTrusted()` — if not trusted, prompt user
2. Initialize WindowManager (creates NotchWindow)
3. Install hooks (HookInstaller — copy script, update settings.json)
4. Start HookSocketServer (bind socket, validate `protocol_version` on received messages)
5. Start ClaudeSessionMonitor (begins 5-second polling timer)
6. Initialize Sparkle updater
7. Set up boot animation (brief expand → collapse)

Reference original `ClaudeIsland/App/AppDelegate.swift`.

- [ ] **Step 2: Verify full build**

```bash
xcodebuild build -scheme Notchy 2>&1 | tail -10
```

- [ ] **Step 3: Test run — app should launch, show notch overlay, and install hooks**

```bash
open build/Debug/Notchy.app
# Verify:
# 1. Black notch shape appears at top of screen
# 2. ~/.claude/hooks/notchy-state.py exists
# 3. Boot animation plays (brief expand then collapse)
```

- [ ] **Step 4: Commit**

```bash
git add Notchy/Notchy/App/AppDelegate.swift && git commit -m "feat: wire up AppDelegate — all services initialized on launch"
```

### Task 25: Build & Release Scripts

**Files:**
- Create: `Notchy/scripts/build.sh`
- Create: `Notchy/scripts/create-release.sh`
- Create: `Notchy/scripts/generate-keys.sh`

- [ ] **Step 1: Create build.sh**

```bash
#!/bin/bash
set -euo pipefail
xcodebuild -scheme Notchy -configuration Release build
```

- [ ] **Step 2: Create create-release.sh**

Reference original. Creates DMG or ZIP for distribution. Signs with Developer ID if available.

- [ ] **Step 3: Create generate-keys.sh**

Generates EdDSA signing keys for Sparkle updates. Reference original.

- [ ] **Step 4: Make scripts executable**

```bash
chmod +x Notchy/scripts/*.sh
```

- [ ] **Step 5: Commit**

```bash
git add Notchy/scripts/ && git commit -m "feat: add build, release, and key generation scripts"
```

### Task 26: License

**Files:**
- Create: `Notchy/LICENSE.md`

- [ ] **Step 1: Create Apache 2.0 LICENSE.md**

- [ ] **Step 2: Final commit**

```bash
git add Notchy/LICENSE.md && git commit -m "feat: add Apache 2.0 license"
```

---

## Chunk 12: End-to-End Verification

### Task 27: Full Integration Test

- [ ] **Step 1: Clean build**

```bash
cd Notchy && xcodebuild clean build -scheme Notchy -configuration Debug 2>&1 | tail -10
```
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Launch app and verify core functionality**

```bash
open build/Debug/Notchy.app
```

Manual verification checklist:
- [ ] App launches without dock icon (LSUIElement)
- [ ] Black notch shape renders at screen notch
- [ ] Boot animation plays (expand → collapse)
- [ ] Hover over notch for 1s → expands
- [ ] Click outside → collapses
- [ ] Hook script installed at `~/.claude/hooks/notchy-state.py`
- [ ] Settings menu accessible (gear icon)
- [ ] Screen picker shows display options
- [ ] Sound picker lists 15 sounds
- [ ] Launch at login toggle works

- [ ] **Step 3: Test with active Claude Code session in tmux**

```bash
tmux new-session -d -s test "claude"
```

Verify:
- [ ] Session appears in instances list
- [ ] Status indicator updates (idle → processing)
- [ ] Chat view shows conversation
- [ ] Tool approval works (Allow/Deny buttons)

- [ ] **Step 4: Final commit with any fixes**

```bash
git add -A && git commit -m "fix: integration test fixes"
```
