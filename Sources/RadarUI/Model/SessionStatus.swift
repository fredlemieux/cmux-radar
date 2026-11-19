/// What a session needs from the user, in display terms.
public nonisolated enum SessionStatus: String, CaseIterable, Sendable {
    /// The agent finished its turn and is waiting for a reply.
    case waiting
    /// The agent is blocked on a permission prompt.
    case permission
    /// The agent is running.
    case working
    /// Nothing is happening.
    case idle

    /// Spoken by VoiceOver and shown in tooltips.
    public var accessibilityName: String {
        switch self {
        case .waiting: "Needs your reply"
        case .permission: "Needs permission"
        case .working: "Working"
        case .idle: "Idle"
        }
    }

    /// Whether the status asks for the user's attention (pulses, counts in the badge).
    public var needsAttention: Bool {
        switch self {
        case .waiting, .permission: true
        case .working, .idle: false
        }
    }
}
