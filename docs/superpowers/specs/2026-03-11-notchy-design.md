# Notchy — Design Specification

A native macOS menu bar app that lives in the MacBook's physical notch area. It monitors active Claude Code CLI sessions in real time, displays session status, allows tool approval/denial, shows chat history, and sends messages — all without switching to the terminal.

1:1 feature clone of [Claude Island](https://github.com/farouqaldori/claude-island), rebranded as "Notchy".

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 6+ |
| UI | SwiftUI + AppKit hybrid |
| Concurrency | Swift actors, async/await, Combine |
| IPC | Unix domain socket (`/tmp/notchy.sock`) |
| Hook Script | Python 3 (`notchy-state.py`) |
| Session Parsing | JSONL from `~/.claude/projects/` |
| Window | Custom NSPanel (borderless, non-activating, click-through) |
| Terminal | tmux integration (send-keys for approvals/messages) |
| Markdown | swift-markdown (SPM) |
| Auto-Updates | Sparkle (SPM), placeholder appcast URL |
| Build | Xcode project, SPM dependencies |
| Min OS | macOS 15.6+ |
| License | Apache 2.0 |

## Architecture

### Communication Flow

```
Claude Code CLI (in tmux)
    │
    │ fires hook events (UserPromptSubmit, PreToolUse, PostToolUse,
    │   PermissionRequest, Notification, Stop, PreCompact, SubagentStop)
    ▼
Python Hook Script (~/.claude/hooks/notchy-state.py)
    │
    │ JSON payloads over Unix domain socket
    │ Blocks for permission responses (allow/deny)
    ▼
Notchy App (SwiftUI + AppKit)
    │
    ├── Also parses JSONL files from ~/.claude/projects/ for chat history
    ├── Matches sessions to tmux panes via PID/process tree
    └── Sends approvals/messages via tmux send-keys
```

### Core Components

1. **SessionStore (Actor)** — Single source of truth for all session state. All mutations go through `process(event:)`. Publishes via Combine for the UI layer.

2. **HookSocketServer** — Unix socket server at `/tmp/notchy.sock`. Receives JSON from the Python hook. For permission requests, blocks waiting for a response (allow/deny) from the app.

3. **NotchViewModel** — Main SwiftUI state: open/close/pop, hover detection, sizing, chat persistence. Drives the UI state machine.

4. **ConversationParser** — JSONL parser for chat history. Supports full and incremental parsing. Extracts tool results for 14+ tool types.

5. **SessionPhase (State Machine)** — Validated transitions: `idle → processing → waitingForInput → waitingForApproval → compacting → ended`.

6. **NotchWindow (NSPanel)** — Custom transparent, borderless, non-activating panel at `mainMenu + 3` level. Joins all Spaces, stationary (ignores Exposé).

### Hook Installation

On launch, the app:
1. Copies `notchy-state.py` to `~/.claude/hooks/`
2. Registers hook events in Claude Code's `settings.json`
3. Starts the Unix socket server at `/tmp/notchy.sock`

## Project Structure

```
Notchy/
├── Notchy.xcodeproj/
├── Notchy/
│   ├── Info.plist                          # LSUIElement=true, Sparkle config
│   ├── App/
│   │   ├── NotchyApp.swift                 # @main entry, empty Settings scene
│   │   ├── AppDelegate.swift               # Window setup, single-instance, Sparkle
│   │   ├── WindowManager.swift             # Notch window lifecycle
│   │   └── ScreenObserver.swift            # Display change notifications
│   ├── Core/
│   │   ├── Ext+NSScreen.swift              # notchSize, hasPhysicalNotch, isBuiltinDisplay
│   │   ├── NotchActivityCoordinator.swift  # Singleton for expanding activity animations
│   │   ├── NotchGeometry.swift             # Hit-testing, coordinate transforms, panel sizing
│   │   ├── NotchViewModel.swift            # Main state: open/close/pop, hover, sizing
│   │   ├── ScreenSelector.swift            # Multi-display support, auto/manual selection
│   │   ├── Settings.swift                  # UserDefaults for preferences
│   │   └── SoundSelector.swift             # Sound picker UI state
│   ├── Events/
│   │   ├── EventMonitor.swift              # NSEvent global+local monitor wrapper
│   │   └── EventMonitors.swift             # Singleton: mouse location + mouse down publishers
│   ├── Models/
│   │   ├── ChatMessage.swift               # ChatMessage, ChatRole, MessageBlock, ToolUseBlock
│   │   ├── SessionEvent.swift              # Unified event enum for state machine
│   │   ├── SessionPhase.swift              # State machine with validated transitions
│   │   ├── SessionState.swift              # Unified session model, ToolTracker, SubagentState
│   │   ├── TmuxTarget.swift                # session:window.pane targeting
│   │   └── ToolResultData.swift            # Typed results for 14 tool types + status display
│   ├── Resources/
│   │   ├── Notchy.entitlements             # App sandbox, network
│   │   └── notchy-state.py                 # Python hook script
│   ├── Services/
│   │   ├── Chat/
│   │   │   └── ChatHistoryManager.swift    # Observable history manager, JSONL sync
│   │   ├── Hooks/
│   │   │   ├── HookInstaller.swift         # Installs Python script + updates settings.json
│   │   │   └── HookSocketServer.swift      # Unix socket server, permission handling
│   │   ├── Session/
│   │   │   ├── AgentFileWatcher.swift      # Watches agent JSONL files
│   │   │   ├── ClaudeSessionMonitor.swift  # MainActor UI binding, approve/deny
│   │   │   ├── ConversationParser.swift    # JSONL parser (full + incremental)
│   │   │   └── JSONLInterruptWatcher.swift # Detects session interrupts
│   │   ├── Shared/
│   │   │   ├── ProcessExecutor.swift       # Async shell command execution
│   │   │   ├── ProcessTreeBuilder.swift    # Process tree for PID matching
│   │   │   └── TerminalAppRegistry.swift   # Terminal emulator detection
│   │   ├── State/
│   │   │   ├── FileSyncScheduler.swift     # Debounced file sync (100ms)
│   │   │   ├── SessionStore.swift          # Actor-based central state
│   │   │   └── ToolEventProcessor.swift    # PreToolUse/PostToolUse + subagent handling
│   │   ├── Tmux/
│   │   │   ├── TmuxController.swift        # Tmux session queries
│   │   │   ├── TmuxPathFinder.swift        # Locates tmux binary
│   │   │   ├── TmuxSessionMatcher.swift    # Matches sessions to tmux panes
│   │   │   ├── TmuxTargetFinder.swift      # Finds tmux target for a TTY
│   │   │   └── ToolApprovalHandler.swift   # Sends approval keys via tmux send-keys
│   │   ├── Update/
│   │   │   └── NotchUserDriver.swift       # Sparkle update UI driver
│   │   └── Window/
│   │       ├── WindowFinder.swift          # Window discovery
│   │       ├── WindowFocuser.swift         # Window focus logic
│   │       └── YabaiController.swift       # yabai window manager integration
│   ├── UI/
│   │   ├── Components/
│   │   │   ├── ActionButton.swift          # Reusable button with hover effects
│   │   │   ├── MarkdownRenderer.swift      # Markdown rendering with document cache
│   │   │   ├── NotchShape.swift            # Custom Shape with quadratic Bezier curves
│   │   │   ├── ProcessingSpinner.swift     # Animated symbol spinner (6 Unicode glyphs)
│   │   │   ├── ScreenPickerRow.swift       # Display selection UI
│   │   │   ├── SoundPickerRow.swift        # Sound selection UI
│   │   │   ├── StatusIcons.swift           # Pixel-art status icons via Canvas
│   │   │   └── TerminalColors.swift        # Color palette
│   │   ├── Views/
│   │   │   ├── ChatView.swift              # Full chat interface
│   │   │   ├── ClaudeInstancesView.swift   # Session list with status
│   │   │   ├── NotchHeaderView.swift       # Crab icon, indicators
│   │   │   ├── NotchMenuView.swift         # Settings panel
│   │   │   ├── NotchView.swift             # Main notch view container
│   │   │   └── ToolResultViews.swift       # 14+ specialized tool renderers
│   │   └── Window/
│   │       ├── NotchViewController.swift   # AppKit hosting with hit-testing
│   │       ├── NotchWindow.swift           # Custom NSPanel
│   │       └── NotchWindowController.swift # Window positioning, boot animation
│   └── Utilities/
│       ├── MCPToolFormatter.swift          # MCP tool name formatting
│       ├── SessionPhaseHelpers.swift       # Phase utility methods
│       └── TerminalVisibilityDetector.swift
├── scripts/
│   ├── build.sh                            # Build script
│   ├── create-release.sh                   # Release packaging
│   └── generate-keys.sh                    # Sparkle signing keys
└── LICENSE.md
```

## UI Design

### Notch Window

- **Type:** Custom NSPanel, borderless, transparent background
- **Level:** `NSWindow.Level.mainMenu + 3`
- **Behavior:** Non-activating, joins all Spaces, stationary (ignores Exposé)
- **App config:** `LSUIElement = true` (no dock icon), single-instance enforced

### Three Visual States

#### 1. Closed
- Renders the notch shape matching the physical MacBook notch using quadratic Bezier curves
- Shows status indicators: animated crab icon, pixel-art permission/ready icons, processing spinner
- Click-through — mouse events pass to windows below
- Hover for 1 second triggers auto-expansion

#### 2. Popping
- Slightly expanded notch for brief activity notifications
- Spring animation (response: 0.42, damping: 0.45)
- Shows what triggered the pop (e.g., "Approval needed")

#### 3. Opened
- Full dropdown panel below the notch
- Contains session list, chat view, or settings menu
- Click outside closes the panel and re-posts the click to underlying windows

### Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Green | #50fa7b | Session ready, waiting for input |
| Amber | #f0c040 | Approval needed |
| Red | #ff5555 | Errors |
| Cyan | #8be9fd | Running processes |
| Claude Orange | #d97857 | Processing spinner, prompt accent |
| Background | #000000 | Notch background |
| Text | #ffffff at 0.2-1.0 opacity | All text |

### Views

#### NotchHeaderView
- Animated crab icon (Claude mascot) with walking leg animation during processing
- Amber pixel-art permission indicator when approval needed
- Green checkmark pixel-art when ready for input

#### ClaudeInstancesView
- All active Claude Code sessions sorted by priority (active > waiting > idle)
- Each row: project name, status indicator, action buttons
- Inline Allow/Deny buttons for permission requests with staggered spring animations
- Chat button to open session conversation
- Focus button (for tmux sessions with yabai) to switch to terminal window
- Archive button for idle sessions

#### ChatView
- Full conversation with user messages (right-aligned, rounded bubble) and assistant messages (left-aligned with white dot)
- Tool calls show colored status dots (pulsing for running/waiting, solid for complete)
- Expandable tool results with 14+ specialized renderers
- Edit tools show inline diffs computed via LCS algorithm
- Inverted ScrollView for bottom-anchored chat with auto-scroll pause/resume
- "N new messages" floating indicator when scrolled up
- Input bar with TextField for sending messages to tmux sessions
- Approval bar with Allow/Deny capsule buttons

#### ToolResultViews
Specialized renderers for: Read, Edit, Write, Bash, Grep, Glob, WebFetch, WebSearch, Task, TodoWrite, AskUserQuestion, MCP tools, and more.

#### NotchMenuView (Settings)
- Screen picker (auto or manual display selection)
- Sound picker (15 notification sounds: Pop, Ping, Glass, etc.)
- Launch at login toggle (ServiceManagement)
- Hook installation status and reinstall button
- Accessibility permission check
- Sparkle update management with progress indicators
- GitHub link and Quit button

### Animations
- Spring animations for open/close (response: 0.42, damping: 0.45)
- Processing spinner: 6 rotating Unicode glyphs in Claude Orange
- Crab legs walking animation during processing
- Pulsing status dots for active tool calls
- Staggered spring animations on permission request buttons
- Boot animation on launch (brief open then close)

## Features

### Session Monitoring
- Discovers active Claude Code sessions via process tree scanning
- Watches JSONL conversation files for real-time updates
- Tracks session phase transitions via state machine
- Supports multiple concurrent sessions
- Handles subagent sessions

### Hook System
- Installs Python hook script to `~/.claude/hooks/notchy-state.py`
- Registers for events: UserPromptSubmit, PreToolUse, PostToolUse, PermissionRequest, Notification, Stop, PreCompact, SubagentStop
- Updates Claude Code's `settings.json` with hook configuration
- Unix socket communication at `/tmp/notchy.sock`

### Tool Approval
- Permission requests shown in notch UI with Allow/Deny buttons
- Approvals sent via tmux send-keys to the correct session pane
- Supports approving from both instances list and chat view
- Python hook blocks until response received over socket

### Chat History
- Parses JSONL conversation files from `~/.claude/projects/`
- Full and incremental parsing for performance
- Renders markdown content
- Shows tool calls with expandable results
- Supports sending messages to tmux sessions

### Notification Sounds
- 15 built-in macOS notification sounds
- Plays when tasks complete or need attention
- Configurable sound selection via settings

### Multi-Display Support
- Detects displays with physical notch
- Auto-selects built-in display or allows manual selection
- Persists screen preference
- Responds to display configuration changes

### Window Management
- yabai integration for window focusing
- Terminal window discovery and focus
- Process tree walking for PID matching

### Auto-Updates
- Sparkle framework integration
- Placeholder appcast URL (to be configured)
- Update progress shown in settings menu

## Dependencies (SPM)

1. **swift-markdown** — Markdown parsing and rendering
2. **Sparkle** — Auto-update framework

## Excluded from Original

- **Mixpanel analytics** — removed, not needed
