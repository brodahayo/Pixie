import Foundation

enum SessionPhase: String, Codable, Sendable {
    case idle
    case processing
    case waitingForInput
    case waitingForApproval
    case compacting
    case ended

    func canTransition(to next: SessionPhase) -> Bool {
        switch (self, next) {
        case (.idle, .processing),
             (.processing, .waitingForInput),
             (.processing, .waitingForApproval),
             (.processing, .compacting),
             (.processing, .idle),
             (.processing, .ended),
             (.waitingForInput, .processing),
             (.waitingForApproval, .processing),
             (.compacting, .processing),
             (.idle, .ended),
             (_, .ended),
             (_, .idle):
            return true
        default:
            return false
        }
    }
}
