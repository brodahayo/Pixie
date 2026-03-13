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

    @State private var shimmerOffset: CGFloat = -1.0
    @State private var pulseOpacity: Double = 0.8
    @State private var timeRefresh: Date = Date()

    private var themeColor: Color {
        MascotColorPreset.resolve(Settings.mascotColor)
    }

    private let elapsedTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

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
                LazyVStack(spacing: 6) {
                    ForEach(sortedInstances) { session in
                        sessionPanel(session)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            }
            .onReceive(elapsedTimer) { date in
                timeRefresh = date
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseOpacity = 0.4
                }
                withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: false)) {
                    shimmerOffset = 1.0
                }
            }
        }
    }

    // MARK: - Session Panel

    @ViewBuilder
    private func sessionPanel(_ session: SessionState) -> some View {
        let (badgeLabel, badgeColor) = statusBadgeInfo(session.phase)

        VStack(alignment: .leading, spacing: 6) {
            // Top row: project name + badge
            HStack(alignment: .center, spacing: 0) {
                Text(session.projectName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                Text(badgeLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(badgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(badgeColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            // Status row: dot + phase label + elapsed time
            HStack(spacing: 5) {
                Circle()
                    .fill(phaseColor(session.phase))
                    .frame(width: 6, height: 6)
                    .opacity(pulseOpacity)

                Text(phaseLabel(session.phase))
                    .font(.system(size: 10))
                    .foregroundColor(phaseColor(session.phase))

                Text("· \(elapsedString(since: session.createdAt))")
                    .font(.system(size: 10))
                    .foregroundColor(Color.secondary)

                Spacer()
            }

            // Last tool row
            if let lastTool = session.lastToolName {
                Text("last: \(lastTool)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Color(white: 0.4))
                    .lineLimit(1)
            }

            // Liquid shimmer progress
            liquidShimmer(phase: session.phase)

            // Approval buttons (when waiting for approval)
            if case .waitingForApproval = session.phase,
               let permission = session.activePermission {
                approvalButtons(session: session, permission: permission)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8, anchor: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [panelGradientTop(session.phase), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(panelBorderColor(session.phase), lineWidth: 1)
        )
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            onOpenChat(session.sessionId)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: session.phase.isWaitingForApproval)
    }

    // MARK: - Approval Buttons

    private func approvalButtons(session: SessionState, permission: PermissionContext) -> some View {
        HStack(spacing: 8) {
            if let toolName = session.pendingToolName {
                Text(toolName)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.orange)
                    .lineLimit(1)
            }

            Spacer()

            Button("Allow") {
                Task {
                    await ToolApprovalHandler.shared.approve(
                        sessionId: session.sessionId,
                        toolUseId: permission.toolUseId,
                        pid: session.pid
                    )
                }
            }
            .buttonStyle(PillButtonStyle(isPrimary: true, isSmall: true))

            Button("Deny") {
                Task {
                    await ToolApprovalHandler.shared.deny(
                        sessionId: session.sessionId,
                        toolUseId: permission.toolUseId,
                        reason: nil,
                        pid: session.pid
                    )
                }
            }
            .buttonStyle(PillButtonStyle(isPrimary: false, isSmall: true))
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Text("No active sessions")
            .font(.system(size: 12))
            .foregroundColor(Color(white: 0.4))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Methods

    private func phaseLabel(_ phase: SessionPhase) -> String {
        switch phase {
        case .processing: return "processing"
        case .compacting: return "compacting"
        case .waitingForApproval: return "approval"
        case .waitingForInput: return "done"
        default: return "idle"
        }
    }

    private func phaseColor(_ phase: SessionPhase) -> Color {
        switch phase {
        case .processing, .compacting: return themeColor
        case .waitingForApproval: return Color.orange
        case .waitingForInput: return themeColor
        default: return Color(white: 0.4)
        }
    }

    private func statusBadgeInfo(_ phase: SessionPhase) -> (String, Color) {
        switch phase {
        case .processing, .compacting: return ("LIVE", themeColor)
        case .waitingForApproval: return ("WAIT", Color.orange)
        case .waitingForInput: return ("DONE", Color.secondary)
        default: return ("IDLE", Color(white: 0.4))
        }
    }

    private func elapsedString(since date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        let minutes = seconds / 60
        let secs = seconds % 60
        return minutes > 0 ? "\(minutes)m \(secs)s" : "\(secs)s"
    }

    @ViewBuilder
    private func liquidShimmer(phase: SessionPhase) -> some View {
        let isActive: Bool = {
            switch phase {
            case .processing, .compacting, .waitingForApproval: return true
            default: return false
            }
        }()

        GeometryReader { geo in
            ZStack {
                // Background tint
                RoundedRectangle(cornerRadius: 2)
                    .fill(shimmerBaseColor(phase).opacity(isActive ? 0.18 : 0.08))

                // Traveling glow (only for active states)
                if isActive {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: shimmerBaseColor(phase).opacity(0), location: 0),
                                    .init(color: shimmerBaseColor(phase).opacity(0.5), location: 0.3),
                                    .init(color: shimmerBaseColor(phase).opacity(0.9), location: 0.5),
                                    .init(color: shimmerBaseColor(phase).opacity(0.5), location: 0.7),
                                    .init(color: shimmerBaseColor(phase).opacity(0), location: 1.0),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.35)
                        .offset(x: shimmerOffset * geo.size.width * 0.7)
                }
            }
        }
        .frame(height: 4)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    private func shimmerBaseColor(_ phase: SessionPhase) -> Color {
        switch phase {
        case .processing, .compacting, .waitingForInput: return themeColor
        case .waitingForApproval: return Color.orange
        default: return Color(white: 0.4)
        }
    }

    private func panelGradientTop(_ phase: SessionPhase) -> Color {
        switch phase {
        case .waitingForApproval: return Color.orange.opacity(0.05)
        default: return Color.white.opacity(0.03)
        }
    }

    private func panelBorderColor(_ phase: SessionPhase) -> Color {
        switch phase {
        case .waitingForApproval: return Color.orange.opacity(0.13)
        default: return Color(NSColor.separatorColor)
        }
    }

    // MARK: - Phase Priority

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
