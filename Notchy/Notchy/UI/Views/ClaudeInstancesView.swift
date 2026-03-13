//
//  ClaudeInstancesView.swift
//  Notchy
//
//  Lists active Claude sessions with status and actions
//

import SwiftUI

struct ClaudeInstancesView: View {
    @ObservedObject var sessionMonitor: ClaudeSessionMonitor
    let onOpenChat: (String) -> Void

    private var sortedInstances: [SessionState] {
        sessionMonitor.instances.sorted { a, b in
            phasePriority(a.phase) > phasePriority(b.phase)
        }
    }

    var body: some View {
        if sortedInstances.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(sortedInstances) { session in
                        SessionRow(session: session, onOpenChat: onOpenChat)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No active sessions")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(TerminalColors.dim)
            Text("Start Claude Code in a terminal")
                .font(.system(size: 10))
                .foregroundColor(TerminalColors.dimmer)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func phasePriority(_ phase: SessionPhase) -> Int {
        switch phase {
        case .waitingForApproval: return 5
        case .waitingForInput: return 4
        case .processing, .compacting: return 3
        case .idle: return 2
        case .ended: return 1
        }
    }
}

// MARK: - Session Row

private struct SessionRow: View {
    let session: SessionState
    let onOpenChat: (String) -> Void
    @State private var showActions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Main row
            HStack(spacing: 6) {
                statusDot

                VStack(alignment: .leading, spacing: 1) {
                    Text(session.projectName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(phaseLabel)
                        .font(.system(size: 9))
                        .foregroundColor(phaseColor.opacity(0.8))
                }

                Spacer()

                // Action buttons
                HStack(spacing: 4) {
                    // Chat button
                    Button {
                        onOpenChat(session.sessionId)
                    } label: {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 10))
                            .foregroundColor(TerminalColors.dim)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)

                    // Focus button (only when pid available)
                    if session.pid != nil {
                        Button {
                            focusTerminal()
                        } label: {
                            Image(systemName: "macwindow")
                                .font(.system(size: 10))
                                .foregroundColor(TerminalColors.dim)
                                .frame(width: 22, height: 22)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(TerminalColors.background)
            .cornerRadius(6)
            .contentShape(Rectangle())

            // Approval buttons (when waiting for approval)
            if let permission = session.activePermission {
                approvalButtons(permission: permission)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8, anchor: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: session.phase.isWaitingForApproval)
    }

    // MARK: - Status Dot

    @ViewBuilder
    private var statusDot: some View {
        Circle()
            .fill(phaseColor)
            .frame(width: 8, height: 8)
    }

    private var phaseColor: Color {
        switch session.phase {
        case .waitingForApproval: return TerminalColors.amber
        case .waitingForInput: return TerminalColors.green
        case .processing, .compacting: return TerminalColors.cyan
        case .idle: return TerminalColors.dim
        case .ended: return TerminalColors.dimmer
        }
    }

    private var phaseLabel: String {
        switch session.phase {
        case .waitingForApproval(let ctx):
            return "Approval: \(ctx.toolName)"
        case .waitingForInput:
            return "Ready"
        case .processing:
            return "Processing"
        case .compacting:
            return "Compacting"
        case .idle:
            return "Idle"
        case .ended:
            return "Ended"
        }
    }

    // MARK: - Approval Buttons

    private func approvalButtons(permission: PermissionContext) -> some View {
        HStack(spacing: 8) {
            // Tool info
            if let toolName = session.pendingToolName {
                Text(toolName)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(TerminalColors.amber)
            }

            Spacer()

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
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                    .background(TerminalColors.green.opacity(0.8))
                    .cornerRadius(10)
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
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                    .background(TerminalColors.red.opacity(0.8))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(TerminalColors.amber.opacity(0.08))
        .cornerRadius(6)
    }

    // MARK: - Actions

    private func focusTerminal() {
        guard let pid = session.pid else { return }
        Task {
            _ = await WindowFocuser.shared.focusTerminalWindow(forSessionPid: pid)
        }
    }
}
