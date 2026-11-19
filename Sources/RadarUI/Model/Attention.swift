/// The two statuses that ask for the user. Count badges only come in these two colours.
public nonisolated enum Attention: Sendable {
    case waiting
    case permission

    var status: SessionStatus {
        switch self {
        case .waiting: .waiting
        case .permission: .permission
        }
    }
}
