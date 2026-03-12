//
//  NotchViewStubs.swift
//  Notchy
//
//  STUB: will be replaced in Task 9
//  Minimal stubs for NotchViewModel, NotchView, and NotchGeometry
//  so the window infrastructure can compile.
//

import AppKit
import Combine
import SwiftUI

// MARK: - NotchStatus

// STUB: will be replaced in Task 9
enum NotchStatus: Equatable, Sendable {
    case closed
    case opened
    case popping
}

// STUB: will be replaced in Task 9
enum OpenReason: Sendable {
    case click
    case notification
    case boot
}

// MARK: - NotchGeometry

// STUB: will be replaced in Task 9
@MainActor
struct NotchGeometry {
    let deviceNotchRect: CGRect
    let screenRect: CGRect
    let windowHeight: CGFloat
    let hasPhysicalNotch: Bool
}

// MARK: - NotchViewModel

// STUB: will be replaced in Task 9
@MainActor
final class NotchViewModel: ObservableObject {
    @Published var status: NotchStatus = .closed
    @Published var openReason: OpenReason = .click

    let geometry: NotchGeometry

    /// Size when the notch panel is fully opened
    var openedSize: CGSize {
        CGSize(width: 400, height: 500)
    }

    init(
        deviceNotchRect: CGRect,
        screenRect: CGRect,
        windowHeight: CGFloat,
        hasPhysicalNotch: Bool
    ) {
        self.geometry = NotchGeometry(
            deviceNotchRect: deviceNotchRect,
            screenRect: screenRect,
            windowHeight: windowHeight,
            hasPhysicalNotch: hasPhysicalNotch
        )
    }

    /// Boot animation: briefly open then close
    func performBootAnimation() {
        status = .popping
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.status = .closed
        }
    }
}

// MARK: - NotchView

// STUB: will be replaced in Task 9
struct NotchView: View {
    @ObservedObject var viewModel: NotchViewModel

    var body: some View {
        Color.clear
            .frame(
                width: viewModel.geometry.screenRect.width,
                height: viewModel.geometry.windowHeight
            )
    }
}
