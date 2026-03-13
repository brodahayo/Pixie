//
//  NotchView.swift
//  Notchy
//
//  The main dynamic island SwiftUI view with accurate notch shape
//

import AppKit
import CoreGraphics
import SwiftUI

// Corner radius constants
private let cornerRadiusInsets = (
    opened: (top: CGFloat(19), bottom: CGFloat(24)),
    closed: (top: CGFloat(6), bottom: CGFloat(14))
)

struct NotchView: View {
    @ObservedObject var viewModel: NotchViewModel
    @StateObject private var sessionMonitor = ClaudeSessionMonitor()
    @StateObject private var activityCoordinator = NotchActivityCoordinator.shared
    @State private var previousPendingIds: Set<String> = []
    @State private var previousWaitingForInputIds: Set<String> = []
    @State private var waitingForInputTimestamps: [String: Date] = [:]
    @State private var isVisible: Bool = false
    @State private var isHovering: Bool = false
    @State private var isBouncing: Bool = false
    @State private var breatheOpacity: Double = 0.35
    @State private var idleStartTime: Date? = nil
    @State private var showSleepZzz: Bool = false
    @State private var zzzPhase: Int = 0
    @State private var selectedTab: Int = 0

    @Namespace private var activityNamespace

    /// Whether any Claude session is currently processing or compacting
    private var isAnyProcessing: Bool {
        sessionMonitor.instances.contains { $0.phase == .processing || $0.phase == .compacting }
    }

    /// Whether any Claude session has a pending permission request
    private var hasPendingPermission: Bool {
        sessionMonitor.instances.contains { $0.phase.isWaitingForApproval }
    }

    /// Whether any Claude session is waiting for user input (done/ready state) within the display window
    private var hasWaitingForInput: Bool {
        let now = Date()
        let displayDuration: TimeInterval = 30  // Show checkmark for 30 seconds

        return sessionMonitor.instances.contains { session in
            guard session.phase == .waitingForInput else { return false }
            if let enteredAt = waitingForInputTimestamps[session.stableId] {
                return now.timeIntervalSince(enteredAt) < displayDuration
            }
            return false
        }
    }

    // MARK: - Sizing

    private var closedNotchSize: CGSize {
        CGSize(
            width: viewModel.deviceNotchRect.width,
            height: viewModel.deviceNotchRect.height
        )
    }

    /// Extra width — always expanded well beyond the physical camera notch
    private var expansionWidth: CGFloat {
        // Expand significantly on each side so mascot + indicators are clearly visible
        return closedNotchSize.width * 0.8
    }

    private var notchSize: CGSize {
        switch viewModel.status {
        case .closed, .popping:
            return closedNotchSize
        case .opened:
            return viewModel.openedSize
        }
    }

    /// Width of the closed content (notch + any expansion)
    private var closedContentWidth: CGFloat {
        closedNotchSize.width + expansionWidth
    }

    // MARK: - Corner Radii

    private var topCornerRadius: CGFloat {
        viewModel.status == .opened
            ? cornerRadiusInsets.opened.top
            : cornerRadiusInsets.closed.top
    }

    private var bottomCornerRadius: CGFloat {
        viewModel.status == .opened
            ? cornerRadiusInsets.opened.bottom
            : cornerRadiusInsets.closed.bottom
    }

    private var currentNotchShape: NotchShape {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius
        )
    }

    // Animation springs
    private let openAnimation = Animation.spring(response: 0.42, dampingFraction: 0.8, blendDuration: 0)
    private let closeAnimation = Animation.spring(response: 0.45, dampingFraction: 1.0, blendDuration: 0)

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                notchLayout
                    .frame(
                        maxWidth: viewModel.status == .opened ? notchSize.width : nil,
                        alignment: .top
                    )
                    .padding(
                        .horizontal,
                        viewModel.status == .opened
                            ? cornerRadiusInsets.opened.top
                            : cornerRadiusInsets.closed.bottom
                    )
                    .padding([.horizontal, .bottom], viewModel.status == .opened ? 12 : 0)
                    .background(.black)
                    .clipShape(currentNotchShape)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(.black)
                            .frame(height: 1)
                            .padding(.horizontal, topCornerRadius)
                    }
                    .shadow(
                        color: (viewModel.status == .opened || isHovering) ? .black.opacity(0.7) : .clear,
                        radius: 6
                    )
                    .frame(
                        maxWidth: viewModel.status == .opened ? notchSize.width : nil,
                        maxHeight: viewModel.status == .opened ? notchSize.height : nil,
                        alignment: .top
                    )
                    .animation(viewModel.status == .opened ? openAnimation : closeAnimation, value: viewModel.status)
                    .animation(openAnimation, value: notchSize)
                    .animation(.smooth, value: activityCoordinator.expandingActivity)
                    .animation(.smooth, value: hasPendingPermission)
                    .animation(.smooth, value: hasWaitingForInput)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isBouncing)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                            isHovering = hovering
                        }
                    }
                    .onTapGesture {
                        if viewModel.status != .opened {
                            viewModel.notchOpen(reason: .click)
                        }
                    }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .preferredColorScheme(.dark)
        .onAppear {
            sessionMonitor.startMonitoring()
            isVisible = true
        }
        .onChange(of: viewModel.status) { oldStatus, newStatus in
            handleStatusChange(from: oldStatus, to: newStatus)
        }
        .onChange(of: sessionMonitor.pendingInstances) { _, sessions in
            handlePendingSessionsChange(sessions)
        }
        .onChange(of: sessionMonitor.instances) { _, instances in
            handleProcessingChange()
            handleWaitingForInputChange(instances)
        }
    }

    // MARK: - Notch Layout

    private var isProcessing: Bool {
        activityCoordinator.expandingActivity.show && activityCoordinator.expandingActivity.type == .claude
    }

    /// Whether to show the expanded closed state (processing, pending permission, or waiting for input)
    private var showClosedActivity: Bool {
        isProcessing || hasPendingPermission || hasWaitingForInput
    }

    @ViewBuilder
    private var notchLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
                .frame(height: max(24, closedNotchSize.height))

            if viewModel.status == .opened {
                // Tab picker sits below the camera notch area
                if case .chat = viewModel.contentType {
                    // No picker in chat — back button is in the header
                } else {
                    HStack {
                        Spacer()
                        Picker("", selection: $selectedTab) {
                            Text("Sessions").tag(0)
                            Text("Config").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                        .onChange(of: selectedTab) { _, newValue in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if newValue == 0 {
                                    viewModel.showInstances()
                                } else {
                                    viewModel.showMenu()
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }

                contentView
                    .frame(width: notchSize.width - 24)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.8, anchor: .top)
                                .combined(with: .opacity)
                                .animation(.smooth(duration: 0.35)),
                            removal: .opacity.animation(.easeOut(duration: 0.15))
                        )
                    )
            }
        }
        .onChange(of: viewModel.contentType) { _, newType in
            switch newType {
            case .instances: selectedTab = 0
            case .menu: selectedTab = 1
            case .chat: break
            }
        }
    }

    // MARK: - Header Row (persists across states)

    @ViewBuilder
    private var headerRow: some View {
        HStack(spacing: 0) {
            if showClosedActivity {
                // Left side: crab only
                MascotIcon(size: 18, animate: isProcessing)
                    .shadow(color: Color.white.opacity(0.15), radius: 6)
                    .matchedGeometryEffect(id: "crab", in: activityNamespace, isSource: showClosedActivity)
                    .frame(
                        width: viewModel.status == .opened ? nil : sideWidth
                    )
                    .padding(.leading, viewModel.status == .opened ? 8 : 0)
            }

            if viewModel.status == .opened {
                openedHeaderContent
            } else if !showClosedActivity {
                // Idle state: same width as active — mascot left, black fill center, zzZ right
                MascotIcon(size: 18)
                    .opacity(breatheOpacity)
                    .shadow(color: Color.white.opacity(breatheOpacity * 0.09), radius: 6)
                    .matchedGeometryEffect(id: "crab", in: activityNamespace, isSource: !showClosedActivity)
                    .frame(width: sideWidth)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                            breatheOpacity = 0.55
                        }
                        // Start tracking idle time
                        idleStartTime = Date()
                        showSleepZzz = false
                        // Show zzZ after 45 seconds of idle
                        DispatchQueue.main.asyncAfter(deadline: .now() + 45) {
                            if !showClosedActivity && viewModel.status != .opened {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showSleepZzz = true
                                }
                            }
                        }
                    }
                    .onDisappear {
                        breatheOpacity = 0.35
                        idleStartTime = nil
                        showSleepZzz = false
                    }

                // Black fill over the physical camera area
                Rectangle()
                    .fill(.black)
                    .frame(width: closedNotchSize.width - cornerRadiusInsets.closed.top)

                // Right side: zzZ sleep indicator (appears after 45s idle)
                ZStack {
                    if showSleepZzz {
                        sleepZzzView
                            .transition(.opacity)
                    }
                }
                .frame(width: sideWidth)
            } else {
                Rectangle()
                    .fill(.black)
                    .frame(
                        width: closedNotchSize.width - cornerRadiusInsets.closed.top
                            + (isBouncing ? 16 : 0)
                    )
            }

            if showClosedActivity {
                if hasPendingPermission {
                    // Permission needed: question mark on the right
                    PermissionIndicatorIcon(
                        size: 14,
                        color: .orange
                    )
                    .shadow(color: Color.orange.opacity(0.3), radius: 6)
                    .matchedGeometryEffect(
                        id: "spinner",
                        in: activityNamespace,
                        isSource: showClosedActivity
                    )
                    .frame(width: viewModel.status == .opened ? 20 : sideWidth)
                } else if isProcessing {
                    // Processing: spinner on the right
                    ProcessingSpinner()
                        .shadow(color: Color.white.opacity(0.15), radius: 4)
                        .matchedGeometryEffect(
                            id: "spinner",
                            in: activityNamespace,
                            isSource: showClosedActivity
                        )
                        .frame(width: viewModel.status == .opened ? 20 : sideWidth)
                } else if hasWaitingForInput {
                    // Done: checkmark on the right
                    ReadyForInputIndicatorIcon(size: 14, color: .green)
                        .shadow(color: Color.white.opacity(0.15), radius: 4)
                        .matchedGeometryEffect(
                            id: "spinner",
                            in: activityNamespace,
                            isSource: showClosedActivity
                        )
                        .frame(width: viewModel.status == .opened ? 20 : sideWidth)
                }
            }
        }
        .frame(height: closedNotchSize.height)
    }

    private var sideWidth: CGFloat {
        max(0, closedNotchSize.height - 12) + 10
    }

    // MARK: - Sleep zzZ Indicator

    private var mascotColor: Color {
        MascotColorPreset.resolve(Settings.mascotColor)
    }

    private var sleepZzzView: some View {
        TimelineView(.periodic(from: .now, by: 0.6)) { timeline in
            let phase = Int(timeline.date.timeIntervalSince1970 / 0.6) % 4
            HStack(spacing: 1) {
                Text("z")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(mascotColor)
                    .opacity(phase >= 1 ? 0.4 : 0.15)
                Text("z")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(mascotColor)
                    .opacity(phase >= 2 ? 0.6 : 0.15)
                Text("Z")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(mascotColor)
                    .opacity(phase >= 3 ? 0.9 : 0.15)
                    .shadow(color: phase >= 3 ? mascotColor.opacity(0.4) : .clear, radius: 4)
            }
        }
    }

    // MARK: - Opened Header Content

    @ViewBuilder
    private var openedHeaderContent: some View {
        HStack(spacing: 12) {
            if !showClosedActivity {
                MascotIcon(size: 18)
                    .matchedGeometryEffect(
                        id: "crab",
                        in: activityNamespace,
                        isSource: !showClosedActivity
                    )
                    .padding(.leading, 8)
            }

            Spacer()

            if case .chat = viewModel.contentType {
                // Back button when in chat
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.exitChat()
                    }
                } label: {
                    Text("←")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Content View (Opened State)

    @ViewBuilder
    private var contentView: some View {
        Group {
            switch viewModel.contentType {
            case .instances:
                ClaudeInstancesView(
                    sessionMonitor: sessionMonitor,
                    onOpenChat: { sessionId in
                        if let session = sessionMonitor.instances.first(where: { $0.sessionId == sessionId }) {
                            viewModel.showChat(for: session)
                        }
                    }
                )
            case .menu:
                NotchMenuView()
            case .chat(let session):
                ChatView(session: session)
            }
        }
        .frame(width: notchSize.width - 24)
        .background(.ultraThinMaterial)
    }

    // MARK: - Event Handlers

    private func handleProcessingChange() {
        if isAnyProcessing || hasPendingPermission {
            activityCoordinator.showActivity(type: .claude)
            isVisible = true
        } else if hasWaitingForInput {
            activityCoordinator.hideActivity()
            isVisible = true
        } else {
            activityCoordinator.hideActivity()
        }
    }

    private func handleStatusChange(from oldStatus: NotchStatus, to newStatus: NotchStatus) {
        switch newStatus {
        case .opened, .popping:
            isVisible = true
            if viewModel.openReason == .click || viewModel.openReason == .hover {
                waitingForInputTimestamps.removeAll()
            }
        case .closed:
            break
        }
    }

    private func handlePendingSessionsChange(_ sessions: [SessionState]) {
        let currentIds = Set(sessions.map { $0.stableId })
        let newPendingIds = currentIds.subtracting(previousPendingIds)

        if !newPendingIds.isEmpty {
            NSSound(named: Settings.notificationSound)?.play()
            if viewModel.status == .closed {
                viewModel.notchOpen(reason: .notification)
            }
        }

        previousPendingIds = currentIds
    }

    private func handleWaitingForInputChange(_ instances: [SessionState]) {
        let waitingForInputSessions = instances.filter { $0.phase == .waitingForInput }
        let currentIds = Set(waitingForInputSessions.map { $0.stableId })
        let newWaitingIds = currentIds.subtracting(previousWaitingForInputIds)

        let now = Date()
        for session in waitingForInputSessions where newWaitingIds.contains(session.stableId) {
            waitingForInputTimestamps[session.stableId] = now
        }

        let staleIds = Set(waitingForInputTimestamps.keys).subtracting(currentIds)
        for staleId in staleIds {
            waitingForInputTimestamps.removeValue(forKey: staleId)
        }

        if !newWaitingIds.isEmpty {
            let newlyWaitingSessions = waitingForInputSessions.filter {
                newWaitingIds.contains($0.stableId)
            }

            // Play notification sound if the session is not actively focused
            if let soundName = NSSound.Name(Settings.notificationSound) as NSSound.Name? {
                Task {
                    let shouldPlay = await shouldPlayNotificationSound(for: newlyWaitingSessions)
                    if shouldPlay {
                        await MainActor.run {
                            NSSound(named: soundName)?.play()
                        }
                    }
                }
            }

            // Trigger bounce animation
            DispatchQueue.main.async {
                isBouncing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBouncing = false
                }
            }

            // Schedule hiding the checkmark after 30 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                handleProcessingChange()
            }
        }

        previousWaitingForInputIds = currentIds
    }

    /// Determine if notification sound should play for the given sessions
    private func shouldPlayNotificationSound(for sessions: [SessionState]) async -> Bool {
        for session in sessions {
            guard let pid = session.pid else {
                return true
            }

            let isFocused = await TerminalVisibilityDetector.isSessionFocused(sessionPid: pid)
            if !isFocused {
                return true
            }
        }

        return false
    }
}
