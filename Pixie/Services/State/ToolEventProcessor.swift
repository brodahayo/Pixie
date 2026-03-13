//
//  ToolEventProcessor.swift
//  Notchy
//
//  Handles tool and subagent event processing logic.
//  Extracted from SessionStore to reduce complexity.
//

import Foundation
import os.log

/// Logger for tool events
private let toolEventLogger = Logger(subsystem: "com.notchy.app", category: "ToolEvents")

/// Processes tool-related events and updates session state
enum ToolEventProcessor {

    // MARK: - Tool Tracking

    /// Process PreToolUse event for tool tracking
    static func processPreToolUse(
        event: HookEvent,
        session: inout SessionState
    ) {
        guard let toolUseId = event.toolUseId, let toolName = event.tool else { return }

        session.toolTracker.startTool(id: toolUseId, name: toolName)

        let toolExists = session.chatItems.contains { $0.id == toolUseId }
        if !toolExists {
            let input = extractToolInput(from: event.toolInput)
            let placeholderItem = ChatHistoryItem(
                id: toolUseId,
                type: .toolCall(ToolCallItem(
                    name: toolName,
                    input: input,
                    status: .running,
                    result: nil,
                    structuredResult: nil,
                    subagentTools: []
                )),
                timestamp: Date()
            )
            session.chatItems.append(placeholderItem)
            toolEventLogger.debug("Created placeholder tool entry for \(toolUseId.prefix(16), privacy: .public)")
        }
    }

    /// Process PostToolUse event for tool tracking
    static func processPostToolUse(
        event: HookEvent,
        session: inout SessionState
    ) {
        guard let toolUseId = event.toolUseId else { return }

        session.toolTracker.completeTool(id: toolUseId, success: true)
        updateToolStatus(in: &session, toolId: toolUseId, status: .success)
    }

    // MARK: - Subagent Tracking

    /// Process PreToolUse event for subagent tracking
    static func processSubagentPreToolUse(
        event: HookEvent,
        session: inout SessionState
    ) {
        guard let toolUseId = event.toolUseId else { return }

        if event.tool == "Task" {
            session.subagentState.startTask(taskToolId: toolUseId)
            toolEventLogger.debug("Started Task subagent tracking: \(toolUseId.prefix(12), privacy: .public)")
        } else if let toolName = event.tool, session.subagentState.hasActiveSubagent {
            toolEventLogger.debug("Adding subagent tool \(toolName, privacy: .public) to active Task")
            let input = extractToolInput(from: event.toolInput)
            let subagentTool = SubagentToolCall(
                id: toolUseId,
                name: toolName,
                input: input,
                status: .running,
                timestamp: Date()
            )
            session.subagentState.addSubagentTool(subagentTool)
        }
    }

    /// Process PostToolUse event for subagent tracking
    static func processSubagentPostToolUse(
        event: HookEvent,
        session: inout SessionState
    ) {
        guard let toolUseId = event.toolUseId else { return }

        if event.tool == "Task" {
            if let taskContext = session.subagentState.activeTasks[toolUseId] {
                toolEventLogger.debug("Task completing with \(taskContext.subagentTools.count) subagent tools")
                attachSubagentToolsToTask(
                    session: &session,
                    taskToolId: toolUseId,
                    subagentTools: taskContext.subagentTools
                )
            }
            session.subagentState.stopTask(taskToolId: toolUseId)
        } else {
            session.subagentState.updateSubagentToolStatus(toolId: toolUseId, status: .success)
        }
    }

    /// Transfer all active subagent tools before stop/interrupt
    static func transferAllSubagentTools(session: inout SessionState, markAsInterrupted: Bool = false) {
        for (taskId, taskContext) in session.subagentState.activeTasks {
            var tools = taskContext.subagentTools
            if markAsInterrupted {
                for i in 0..<tools.count {
                    if tools[i].status == .running {
                        tools[i].status = .interrupted
                    }
                }
            }
            attachSubagentToolsToTask(
                session: &session,
                taskToolId: taskId,
                subagentTools: tools
            )
        }
        session.subagentState = SubagentState()
    }

    // MARK: - Tool Status Updates

    /// Update tool status in session's chat items
    static func updateToolStatus(
        in session: inout SessionState,
        toolId: String,
        status: ToolStatus
    ) {
        for i in 0..<session.chatItems.count {
            if session.chatItems[i].id == toolId,
               case .toolCall(var tool) = session.chatItems[i].type,
               tool.status == .waitingForApproval || tool.status == .running {
                tool.status = status
                session.chatItems[i] = ChatHistoryItem(
                    id: toolId,
                    type: .toolCall(tool),
                    timestamp: session.chatItems[i].timestamp
                )
                return
            }
        }
    }

    /// Find the next tool waiting for approval
    static func findNextPendingTool(
        in session: SessionState,
        excluding toolId: String
    ) -> (id: String, name: String, timestamp: Date)? {
        for item in session.chatItems {
            if item.id == toolId { continue }
            if case .toolCall(let tool) = item.type, tool.status == .waitingForApproval {
                return (id: item.id, name: tool.name, timestamp: item.timestamp)
            }
        }
        return nil
    }

    /// Mark all running tools as interrupted
    static func markRunningToolsInterrupted(session: inout SessionState) {
        for i in 0..<session.chatItems.count {
            if case .toolCall(var tool) = session.chatItems[i].type,
               tool.status == .running {
                tool.status = .interrupted
                session.chatItems[i] = ChatHistoryItem(
                    id: session.chatItems[i].id,
                    type: .toolCall(tool),
                    timestamp: session.chatItems[i].timestamp
                )
            }
        }
    }

    // MARK: - Private Helpers

    private static func attachSubagentToolsToTask(
        session: inout SessionState,
        taskToolId: String,
        subagentTools: [SubagentToolCall]
    ) {
        guard !subagentTools.isEmpty else { return }

        for i in 0..<session.chatItems.count {
            if session.chatItems[i].id == taskToolId,
               case .toolCall(var tool) = session.chatItems[i].type {
                tool.subagentTools = subagentTools
                session.chatItems[i] = ChatHistoryItem(
                    id: taskToolId,
                    type: .toolCall(tool),
                    timestamp: session.chatItems[i].timestamp
                )
                toolEventLogger.debug("Attached \(subagentTools.count) subagent tools to Task \(taskToolId.prefix(12), privacy: .public)")
                break
            }
        }
    }

    /// Extract tool input from JSONValue dictionary
    private static func extractToolInput(from hookInput: [String: JSONValue]?) -> [String: String] {
        var input: [String: String] = [:]
        guard let hookInput = hookInput else { return input }

        for (key, value) in hookInput {
            switch value {
            case .string(let str):
                input[key] = str
            case .number(let num):
                input[key] = String(num)
            case .bool(let b):
                input[key] = b ? "true" : "false"
            default:
                break
            }
        }
        return input
    }
}
