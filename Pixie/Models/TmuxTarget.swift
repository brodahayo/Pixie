import Foundation

struct TmuxTarget: Sendable, Equatable {
    let session: String
    let window: String
    let pane: String

    var targetString: String { "\(session):\(window).\(pane)" }
}
