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

    var id: String {
        switch self {
        case .text(let id, _): return id
        case .thinking(let id, _): return id
        case .toolUse(let block): return block.id
        case .toolResult(let id, _, _): return id
        }
    }
}

struct ToolUseBlock: Sendable, Identifiable {
    let id: String
    let tool: String
    let input: [String: JSONValue]
    var status: ToolStatus = .running
    var result: ToolResultData?
}
