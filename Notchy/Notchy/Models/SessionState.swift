import Foundation

struct SessionState: Sendable, Identifiable, Equatable {
    let id: String
    var phase: SessionPhase = .idle
    var projectName: String = ""
    var cwd: String = ""
    var tmuxTarget: TmuxTarget?
    var activeTools: [ToolTracker] = []
    var pendingPermission: PendingPermission?
    var lastActivity: Date = Date()
    var pid: Int?

    /// Stable identifier (alias for id) used for tracking across state changes
    var stableId: String { id }

    /// Alias for id, used by views expecting sessionId
    var sessionId: String { id }

    static func == (lhs: SessionState, rhs: SessionState) -> Bool {
        lhs.id == rhs.id
    }
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
