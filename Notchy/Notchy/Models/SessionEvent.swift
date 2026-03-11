import Foundation

enum JSONValue: Sendable, Codable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        } else if let numVal = try? container.decode(Double.self) {
            self = .number(numVal)
        } else if let strVal = try? container.decode(String.self) {
            self = .string(strVal)
        } else if let arrVal = try? container.decode([JSONValue].self) {
            self = .array(arrVal)
        } else if let objVal = try? container.decode([String: JSONValue].self) {
            self = .object(objVal)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode JSONValue")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}

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
