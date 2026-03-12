//
//  HookSocketServer.swift
//  Notchy
//
//  Unix domain socket server for real-time hook events
//  Supports request/response for permission decisions
//

import Foundation
import os.log

/// Logger for hook socket server
private let logger = Logger(subsystem: "com.notchy.app", category: "Hooks")

/// Raw event received from the Python hook via Unix socket
struct HookEvent: Codable, Sendable {
    let sessionId: String
    let cwd: String
    let event: String
    let status: String
    let protocolVersion: Int?
    let pid: Int?
    let tty: String?
    let tool: String?
    let toolInput: [String: JSONValue]?
    let toolUseId: String?
    let notificationType: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case cwd, event, status, pid, tty, tool
        case protocolVersion = "protocol_version"
        case toolInput = "tool_input"
        case toolUseId = "tool_use_id"
        case notificationType = "notification_type"
        case message
    }

    /// Whether this event expects a response (permission request)
    var expectsResponse: Bool {
        event == "PermissionRequest" && status == "waiting_for_approval"
    }

    /// Convert to a SessionEvent for the rest of the app
    func toSessionEvent(resolvedToolUseId: String? = nil) -> SessionEvent? {
        let effectiveToolUseId = resolvedToolUseId ?? toolUseId

        switch event {
        case "UserPromptSubmit":
            return .userPromptSubmit(sessionId: sessionId, prompt: "")
        case "PreToolUse":
            return .preToolUse(
                sessionId: sessionId,
                tool: tool ?? "unknown",
                input: toolInput ?? [:]
            )
        case "PostToolUse":
            return .postToolUse(
                sessionId: sessionId,
                tool: tool ?? "unknown",
                output: ""
            )
        case "PermissionRequest":
            return .permissionRequest(
                sessionId: sessionId,
                tool: tool ?? "unknown",
                input: toolInput ?? [:],
                requestId: effectiveToolUseId ?? UUID().uuidString
            )
        case "Notification":
            return .notification(
                sessionId: sessionId,
                title: notificationType ?? "",
                body: message ?? ""
            )
        case "Stop":
            return .stop(sessionId: sessionId, reason: .end)
        case "SubagentStop":
            return .subagentStop(sessionId: sessionId, subagentId: "")
        case "SessionStart":
            return .userPromptSubmit(sessionId: sessionId, prompt: "")
        case "SessionEnd":
            return .sessionGone(sessionId: sessionId)
        case "PreCompact":
            return .preCompact(sessionId: sessionId)
        default:
            return nil
        }
    }
}

/// Response to send back to the hook
struct HookResponse: Codable, Sendable {
    let decision: String // "allow", "deny", or "ask"
    let reason: String?
}

/// Pending permission request waiting for user decision (socket-level)
struct SocketPendingPermission: Sendable {
    let sessionId: String
    let toolUseId: String
    let clientSocket: Int32
    let event: HookEvent
    let receivedAt: Date
}

/// Unix domain socket server that receives events from Claude Code hooks
/// Uses GCD DispatchSource for non-blocking I/O
final class HookSocketServer: Sendable {
    static let socketPath: String = {
        let tmpdir = Foundation.ProcessInfo.processInfo.environment["TMPDIR"] ?? "/tmp"
        return (tmpdir as NSString).appendingPathComponent("notchy.sock")
    }()

    nonisolated(unsafe) private var serverSocket: Int32 = -1
    nonisolated(unsafe) private var acceptSource: DispatchSourceRead?
    nonisolated(unsafe) private var onEvent: (@Sendable (SessionEvent) async -> Void)?
    nonisolated(unsafe) private var onPermissionRequest: (@Sendable (String, String, [String: JSONValue], String) async -> PermissionDecision)?
    private let queue = DispatchQueue(label: "com.notchy.socket", qos: .userInitiated)

    /// Pending permission requests indexed by toolUseId
    nonisolated(unsafe) private var pendingPermissions: [String: SocketPendingPermission] = [:]
    private let permissionsLock = NSLock()

    /// Cache tool_use_id from PreToolUse to correlate with PermissionRequest
    /// Key: "sessionId:toolName:serializedInput" -> Queue of tool_use_ids (FIFO)
    nonisolated(unsafe) private var toolUseIdCache: [String: [String]] = [:]
    private let cacheLock = NSLock()

    /// Encoder with sorted keys for deterministic cache keys
    private static let sortedEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()

    init() {}

    /// Start the socket server
    func start(
        onEvent: @escaping @Sendable (SessionEvent) async -> Void,
        onPermissionRequest: @escaping @Sendable (String, String, [String: JSONValue], String) async -> PermissionDecision
    ) {
        queue.async { [weak self] in
            self?.startServer(onEvent: onEvent, onPermissionRequest: onPermissionRequest)
        }
    }

    private func startServer(
        onEvent: @escaping @Sendable (SessionEvent) async -> Void,
        onPermissionRequest: @escaping @Sendable (String, String, [String: JSONValue], String) async -> PermissionDecision
    ) {
        guard serverSocket < 0 else { return }

        self.onEvent = onEvent
        self.onPermissionRequest = onPermissionRequest

        unlink(Self.socketPath)

        serverSocket = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverSocket >= 0 else {
            logger.error("Failed to create socket: \(errno)")
            return
        }

        let flags = fcntl(serverSocket, F_GETFL)
        _ = fcntl(serverSocket, F_SETFL, flags | O_NONBLOCK)

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        Self.socketPath.withCString { ptr in
            withUnsafeMutablePointer(to: &addr.sun_path) { pathPtr in
                let pathBufferPtr = UnsafeMutableRawPointer(pathPtr)
                    .assumingMemoryBound(to: CChar.self)
                strcpy(pathBufferPtr, ptr)
            }
        }

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                bind(serverSocket, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard bindResult == 0 else {
            logger.error("Failed to bind socket: \(errno)")
            close(serverSocket)
            serverSocket = -1
            return
        }

        chmod(Self.socketPath, 0o777)

        guard listen(serverSocket, 10) == 0 else {
            logger.error("Failed to listen: \(errno)")
            close(serverSocket)
            serverSocket = -1
            return
        }

        logger.info("Listening on \(Self.socketPath, privacy: .public)")

        acceptSource = DispatchSource.makeReadSource(fileDescriptor: serverSocket, queue: queue)
        acceptSource?.setEventHandler { [weak self] in
            self?.acceptConnection()
        }
        acceptSource?.setCancelHandler { [weak self] in
            if let fd = self?.serverSocket, fd >= 0 {
                close(fd)
                self?.serverSocket = -1
            }
        }
        acceptSource?.resume()
    }

    /// Stop the socket server and clean up
    func stop() {
        acceptSource?.cancel()
        acceptSource = nil
        unlink(Self.socketPath)

        permissionsLock.lock()
        for (_, pending) in pendingPermissions {
            close(pending.clientSocket)
        }
        pendingPermissions.removeAll()
        permissionsLock.unlock()
    }

    /// Respond to a pending permission request by toolUseId
    func respondToPermission(toolUseId: String, decision: PermissionDecision, reason: String? = nil) {
        queue.async { [weak self] in
            self?.sendPermissionResponse(toolUseId: toolUseId, decision: decision, reason: reason)
        }
    }

    /// Respond to permission by sessionId (finds the most recent pending for that session)
    func respondToPermissionBySession(sessionId: String, decision: PermissionDecision, reason: String? = nil) {
        queue.async { [weak self] in
            self?.sendPermissionResponseBySession(sessionId: sessionId, decision: decision, reason: reason)
        }
    }

    /// Cancel all pending permissions for a session
    func cancelPendingPermissions(sessionId: String) {
        queue.async { [weak self] in
            self?.cleanupPendingPermissions(sessionId: sessionId)
        }
    }

    /// Check if there's a pending permission request for a session
    func hasPendingPermission(sessionId: String) -> Bool {
        permissionsLock.lock()
        defer { permissionsLock.unlock() }
        return pendingPermissions.values.contains { $0.sessionId == sessionId }
    }

    /// Get the pending permission details for a session (if any)
    func getPendingPermission(sessionId: String) -> (toolName: String?, toolId: String?, toolInput: [String: JSONValue]?)? {
        permissionsLock.lock()
        defer { permissionsLock.unlock() }
        guard let pending = pendingPermissions.values.first(where: { $0.sessionId == sessionId }) else {
            return nil
        }
        return (pending.event.tool, pending.toolUseId, pending.event.toolInput)
    }

    /// Cancel a specific pending permission by toolUseId
    func cancelPendingPermission(toolUseId: String) {
        queue.async { [weak self] in
            self?.cleanupSpecificPermission(toolUseId: toolUseId)
        }
    }

    // MARK: - Tool Use ID Cache

    /// Generate cache key from event properties
    private func cacheKey(sessionId: String, toolName: String?, toolInput: [String: JSONValue]?) -> String {
        let inputStr: String
        if let input = toolInput,
           let data = try? Self.sortedEncoder.encode(input),
           let str = String(data: data, encoding: .utf8) {
            inputStr = str
        } else {
            inputStr = "{}"
        }
        return "\(sessionId):\(toolName ?? "unknown"):\(inputStr)"
    }

    /// Cache tool_use_id from PreToolUse event (FIFO queue per key)
    private func cacheToolUseId(event: HookEvent) {
        guard let toolUseId = event.toolUseId else { return }

        let key = cacheKey(sessionId: event.sessionId, toolName: event.tool, toolInput: event.toolInput)

        cacheLock.lock()
        if toolUseIdCache[key] == nil {
            toolUseIdCache[key] = []
        }
        toolUseIdCache[key]?.append(toolUseId)
        cacheLock.unlock()

        logger.debug("Cached tool_use_id for \(event.sessionId.prefix(8), privacy: .public) tool:\(event.tool ?? "?", privacy: .public)")
    }

    /// Pop and return cached tool_use_id for PermissionRequest (FIFO)
    private func popCachedToolUseId(event: HookEvent) -> String? {
        let key = cacheKey(sessionId: event.sessionId, toolName: event.tool, toolInput: event.toolInput)

        cacheLock.lock()
        defer { cacheLock.unlock() }

        guard var ids = toolUseIdCache[key], !ids.isEmpty else {
            return nil
        }

        let toolUseId = ids.removeFirst()
        if ids.isEmpty {
            toolUseIdCache.removeValue(forKey: key)
        } else {
            toolUseIdCache[key] = ids
        }

        return toolUseId
    }

    /// Clean up cache entries for a session (on session end)
    private func cleanupCache(sessionId: String) {
        cacheLock.lock()
        let keysToRemove = toolUseIdCache.keys.filter { $0.hasPrefix("\(sessionId):") }
        for key in keysToRemove {
            toolUseIdCache.removeValue(forKey: key)
        }
        cacheLock.unlock()
    }

    // MARK: - Private Connection Handling

    private func acceptConnection() {
        let clientSocket = accept(serverSocket, nil, nil)
        guard clientSocket >= 0 else { return }

        var nosigpipe: Int32 = 1
        setsockopt(clientSocket, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe, socklen_t(MemoryLayout<Int32>.size))

        handleClient(clientSocket)
    }

    private func handleClient(_ clientSocket: Int32) {
        let flags = fcntl(clientSocket, F_GETFL)
        _ = fcntl(clientSocket, F_SETFL, flags | O_NONBLOCK)

        var allData = Data()
        var buffer = [UInt8](repeating: 0, count: 131_072)
        var pollFd = pollfd(fd: clientSocket, events: Int16(POLLIN), revents: 0)

        let startTime = Date()
        while Date().timeIntervalSince(startTime) < 0.5 {
            let pollResult = poll(&pollFd, 1, 50)

            if pollResult > 0 && (pollFd.revents & Int16(POLLIN)) != 0 {
                let bytesRead = read(clientSocket, &buffer, buffer.count)

                if bytesRead > 0 {
                    allData.append(contentsOf: buffer[0..<bytesRead])
                } else if bytesRead == 0 {
                    break
                } else if errno != EAGAIN && errno != EWOULDBLOCK {
                    break
                }
            } else if pollResult == 0 {
                if !allData.isEmpty {
                    break
                }
            } else {
                break
            }
        }

        guard !allData.isEmpty else {
            close(clientSocket)
            return
        }

        let data = allData

        guard let event = try? JSONDecoder().decode(HookEvent.self, from: data) else {
            logger.warning("Failed to parse event: \(String(data: data, encoding: .utf8) ?? "?", privacy: .public)")
            close(clientSocket)
            return
        }

        // Validate protocol version
        if let version = event.protocolVersion, version != 1 {
            logger.warning("Unsupported protocol version: \(version)")
            close(clientSocket)
            return
        }

        logger.debug("Received: \(event.event, privacy: .public) for \(event.sessionId.prefix(8), privacy: .public)")

        if event.event == "PreToolUse" {
            cacheToolUseId(event: event)
        }

        if event.event == "SessionEnd" {
            cleanupCache(sessionId: event.sessionId)
        }

        if event.expectsResponse {
            handlePermissionRequest(event: event, clientSocket: clientSocket)
        } else {
            close(clientSocket)
            forwardEvent(event)
        }
    }

    private func handlePermissionRequest(event: HookEvent, clientSocket: Int32) {
        let toolUseId: String
        if let eventToolUseId = event.toolUseId {
            toolUseId = eventToolUseId
        } else if let cachedToolUseId = popCachedToolUseId(event: event) {
            toolUseId = cachedToolUseId
        } else {
            logger.warning("Permission request missing tool_use_id for \(event.sessionId.prefix(8), privacy: .public)")
            close(clientSocket)
            forwardEvent(event)
            return
        }

        logger.debug("Permission request - keeping socket open for \(event.sessionId.prefix(8), privacy: .public) tool:\(toolUseId.prefix(12), privacy: .public)")

        let updatedEvent = HookEvent(
            sessionId: event.sessionId,
            cwd: event.cwd,
            event: event.event,
            status: event.status,
            protocolVersion: event.protocolVersion,
            pid: event.pid,
            tty: event.tty,
            tool: event.tool,
            toolInput: event.toolInput,
            toolUseId: toolUseId,
            notificationType: event.notificationType,
            message: event.message
        )

        let pending = SocketPendingPermission(
            sessionId: event.sessionId,
            toolUseId: toolUseId,
            clientSocket: clientSocket,
            event: updatedEvent,
            receivedAt: Date()
        )
        permissionsLock.lock()
        pendingPermissions[toolUseId] = pending
        permissionsLock.unlock()

        // Forward as session event
        forwardEvent(updatedEvent)

        // Set up 30-second timeout
        queue.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.timeoutPermission(toolUseId: toolUseId)
        }
    }

    private func timeoutPermission(toolUseId: String) {
        permissionsLock.lock()
        guard let pending = pendingPermissions.removeValue(forKey: toolUseId) else {
            permissionsLock.unlock()
            return
        }
        permissionsLock.unlock()

        logger.info("Permission request timed out for \(pending.sessionId.prefix(8), privacy: .public) tool:\(toolUseId.prefix(12), privacy: .public)")
        close(pending.clientSocket)
    }

    private func forwardEvent(_ event: HookEvent) {
        guard let sessionEvent = event.toSessionEvent(), let handler = onEvent else { return }
        Task {
            await handler(sessionEvent)
        }
    }

    private func cleanupSpecificPermission(toolUseId: String) {
        permissionsLock.lock()
        guard let pending = pendingPermissions.removeValue(forKey: toolUseId) else {
            permissionsLock.unlock()
            return
        }
        permissionsLock.unlock()

        logger.debug("Tool completed externally, closing socket for \(pending.sessionId.prefix(8), privacy: .public)")
        close(pending.clientSocket)
    }

    private func cleanupPendingPermissions(sessionId: String) {
        permissionsLock.lock()
        let matching = pendingPermissions.filter { $0.value.sessionId == sessionId }
        for (toolUseId, pending) in matching {
            close(pending.clientSocket)
            pendingPermissions.removeValue(forKey: toolUseId)
        }
        permissionsLock.unlock()
    }

    // MARK: - Permission Response Sending

    private func sendPermissionResponse(toolUseId: String, decision: PermissionDecision, reason: String?) {
        permissionsLock.lock()
        guard let pending = pendingPermissions.removeValue(forKey: toolUseId) else {
            permissionsLock.unlock()
            logger.debug("No pending permission for toolUseId: \(toolUseId.prefix(12), privacy: .public)")
            return
        }
        permissionsLock.unlock()

        let response = HookResponse(decision: decision.rawValue, reason: reason)
        guard let data = try? JSONEncoder().encode(response) else {
            close(pending.clientSocket)
            return
        }

        let age = Date().timeIntervalSince(pending.receivedAt)
        logger.info("Sending response: \(decision.rawValue, privacy: .public) for \(pending.sessionId.prefix(8), privacy: .public) tool:\(toolUseId.prefix(12), privacy: .public) (age: \(String(format: "%.1f", age), privacy: .public)s)")

        data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else {
                logger.error("Failed to get data buffer address")
                return
            }
            let result = write(pending.clientSocket, baseAddress, data.count)
            if result < 0 {
                logger.error("Write failed with errno: \(errno)")
            }
        }

        close(pending.clientSocket)
    }

    private func sendPermissionResponseBySession(sessionId: String, decision: PermissionDecision, reason: String?) {
        permissionsLock.lock()
        let matchingPending = pendingPermissions.values
            .filter { $0.sessionId == sessionId }
            .sorted { $0.receivedAt > $1.receivedAt }
            .first

        guard let pending = matchingPending else {
            permissionsLock.unlock()
            logger.debug("No pending permission for session: \(sessionId.prefix(8), privacy: .public)")
            return
        }

        pendingPermissions.removeValue(forKey: pending.toolUseId)
        permissionsLock.unlock()

        let response = HookResponse(decision: decision.rawValue, reason: reason)
        guard let data = try? JSONEncoder().encode(response) else {
            close(pending.clientSocket)
            return
        }

        let age = Date().timeIntervalSince(pending.receivedAt)
        logger.info("Sending response: \(decision.rawValue, privacy: .public) for \(sessionId.prefix(8), privacy: .public) tool:\(pending.toolUseId.prefix(12), privacy: .public) (age: \(String(format: "%.1f", age), privacy: .public)s)")

        data.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else {
                logger.error("Failed to get data buffer address")
                return
            }
            let result = write(pending.clientSocket, baseAddress, data.count)
            if result < 0 {
                logger.error("Write failed with errno: \(errno)")
            }
        }

        close(pending.clientSocket)
    }
}

