//
//  ScreenObserver.swift
//  Notchy
//
//  Monitors screen configuration changes (display connect/disconnect, resolution changes).
//

import AppKit

@MainActor
final class ScreenObserver {
    private nonisolated(unsafe) var observer: (any NSObjectProtocol)?
    private let onScreenChange: @MainActor @Sendable () -> Void

    init(onScreenChange: @escaping @MainActor @Sendable () -> Void) {
        self.onScreenChange = onScreenChange
        startObserving()
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func startObserving() {
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.onScreenChange()
            }
        }
    }
}
