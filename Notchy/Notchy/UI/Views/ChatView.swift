//
//  ChatView.swift
//  Notchy
//
//  Full conversation view with message list, input bar, and approval controls
//

import SwiftUI

struct ChatView: View {
    let session: SessionState
    @StateObject private var chatHistory = ChatHistoryManager.shared
    @State private var messageText: String = ""
    @State private var expandedTools: Set<String> = []
    @State private var showThinking: Set<String> = []

    private var items: [ChatHistoryItem] {
        chatHistory.history(for: session.sessionId)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Message list (inverted scroll)
            messageList

            // Approval bar (when waiting for approval)
            if let permission = session.activePermission {
                approvalBar(permission: permission)
            }

            // Input bar (when session has a PID for tmux interaction)
            if session.pid != nil {
                inputBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Task {
                await chatHistory.loadFromFile(sessionId: session.sessionId, cwd: session.cwd)
            }
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(items.reversed()) { item in
                    chatItemView(item)
                        .rotationEffect(.degrees(180))
                        .scaleEffect(x: -1, y: 1, anchor: .center)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .rotationEffect(.degrees(180))
        .scaleEffect(x: -1, y: 1, anchor: .center)
    }

    // MARK: - Chat Item Router

    @ViewBuilder
    private func chatItemView(_ item: ChatHistoryItem) -> some View {
        switch item.type {
        case .user(let text):
            userBubble(text)
        case .assistant(let text):
            assistantMessage(text)
        case .toolCall(let tool):
            toolCallRow(tool, itemId: item.id)
        case .thinking(let text):
            thinkingBlock(text, itemId: item.id)
        case .interrupted:
            interruptedIndicator
        }
    }

    // MARK: - User Message

    private func userBubble(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 40)
            Text(text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(TerminalColors.prompt.opacity(0.06))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(TerminalColors.border, lineWidth: 1)
                )
        }
    }

    // MARK: - Assistant Message

    private func assistantMessage(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(MarkdownRenderer.render(text, fontSize: 11))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 20)
        }
    }

    // MARK: - Tool Call Row

    private func toolCallRow(_ tool: ToolCallItem, itemId: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            // Tool header (clickable to expand)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedTools.contains(itemId) {
                        expandedTools.remove(itemId)
                    } else {
                        expandedTools.insert(itemId)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    // Status dot
                    statusDot(tool.status)

                    // Tool name
                    Text(tool.name)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(TerminalColors.cyan)

                    // Input preview
                    Text(tool.inputPreview)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(TerminalColors.dim)
                        .lineLimit(1)

                    Spacer()

                    // Status text
                    Text(tool.statusDisplay.text)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(TerminalColors.dim)

                    // Expand indicator
                    if tool.structuredResult != nil || tool.result != nil {
                        Image(systemName: expandedTools.contains(itemId) ? "chevron.down" : "chevron.right")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(TerminalColors.dimmer)
                    }
                }
                .padding(.vertical, 3)
                .padding(.horizontal, 6)
                .background(TerminalColors.background)
                .cornerRadius(4)
            }
            .buttonStyle(.plain)

            // Expanded result
            if expandedTools.contains(itemId) {
                if let structured = tool.structuredResult {
                    ToolResultView(result: structured)
                        .padding(.leading, 16)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else if let raw = tool.result, !raw.isEmpty {
                    Text(String(raw.prefix(500)))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.7))
                        .lineLimit(10)
                        .padding(.leading, 16)
                        .padding(6)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Subagent tools (for Task tools)
            if !tool.subagentTools.isEmpty {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(tool.subagentTools) { subTool in
                        HStack(spacing: 4) {
                            statusDot(subTool.status)
                                .scaleEffect(0.7)
                            Text(subTool.displayText)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(TerminalColors.dim)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.leading, 16)
            }
        }
    }

    // MARK: - Status Dot

    @ViewBuilder
    private func statusDot(_ status: ToolStatus) -> some View {
        Circle()
            .fill(statusColor(status))
            .frame(width: 6, height: 6)
            .opacity(status == .running || status == .waitingForApproval ? 1.0 : 0.8)
            .animation(
                status == .running || status == .waitingForApproval
                    ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                    : .default,
                value: status
            )
    }

    private func statusColor(_ status: ToolStatus) -> Color {
        switch status {
        case .running: return TerminalColors.cyan
        case .waitingForApproval: return TerminalColors.amber
        case .success: return TerminalColors.green
        case .error: return TerminalColors.red
        case .interrupted: return TerminalColors.amber
        }
    }

    // MARK: - Thinking Block

    private func thinkingBlock(_ text: String, itemId: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if showThinking.contains(itemId) {
                        showThinking.remove(itemId)
                    } else {
                        showThinking.insert(itemId)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showThinking.contains(itemId) ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(TerminalColors.dimmer)
                    Text("Thinking...")
                        .font(.system(size: 10, design: .monospaced).italic())
                        .foregroundColor(TerminalColors.dim)
                }
            }
            .buttonStyle(.plain)

            if showThinking.contains(itemId) {
                Text(text)
                    .font(.system(size: 10, design: .monospaced).italic())
                    .foregroundColor(TerminalColors.dim.opacity(0.7))
                    .padding(.leading, 12)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Interrupted Indicator

    private var interruptedIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 9))
                .foregroundColor(TerminalColors.amber)
            Text("Interrupted")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(TerminalColors.amber)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Approval Bar

    private func approvalBar(permission: PermissionContext) -> some View {
        VStack(spacing: 4) {
            Divider().background(Color.white.opacity(0.1))

            VStack(alignment: .leading, spacing: 4) {
                // Tool info
                HStack(spacing: 4) {
                    Text(permission.toolName)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(TerminalColors.amber)
                    if let input = permission.formattedInput {
                        Text(String(input.prefix(80)))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(TerminalColors.dim)
                            .lineLimit(1)
                    }
                }

                // Buttons
                HStack(spacing: 8) {
                    Button {
                        Task {
                            await ToolApprovalHandler.shared.approve(
                                sessionId: session.sessionId,
                                toolUseId: permission.toolUseId,
                                pid: session.pid
                            )
                        }
                    } label: {
                        Text("Allow")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(TerminalColors.prompt)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(TerminalColors.prompt.opacity(0.12))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(TerminalColors.prompt, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task {
                            await ToolApprovalHandler.shared.deny(
                                sessionId: session.sessionId,
                                toolUseId: permission.toolUseId,
                                reason: nil,
                                pid: session.pid
                            )
                        }
                    } label: {
                        Text("Deny")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(TerminalColors.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(TerminalColors.red.opacity(0.12))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(TerminalColors.red, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
        }
        .background(Color.black.opacity(0.5))
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.1))

            HStack(spacing: 6) {
                TextField("Send message...", text: $messageText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)
                    .onSubmit {
                        sendMessage()
                    }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(messageText.isEmpty ? TerminalColors.dimmer : TerminalColors.prompt)
                }
                .buttonStyle(.plain)
                .disabled(messageText.isEmpty)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let pid = session.pid else { return }
        messageText = ""

        Task {
            _ = await ToolApprovalHandler.shared.sendMessage(text, toPid: pid)
        }
    }
}
