public import Foundation

/// A cmux workstream id, e.g. `claude-3f2a…`.
public struct SessionID: Hashable, Sendable, Comparable, CustomStringConvertible {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String {
        rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Which agent runs the session, read from the workstream id prefix.
public enum AgentKind: Equatable, Sendable {
    case claude
    case codex
    case other(String)

    /// `claude-…` → `.claude`, `codex-…` → `.codex`, anything else → `.other(prefix)`.
    public init(sessionID: SessionID) {
        let prefix = sessionID.rawValue.split(separator: "-", maxSplits: 1).first.map(String.init) ?? ""
        switch prefix {
        case "claude": self = .claude
        case "codex": self = .codex
        default: self = .other(prefix)
        }
    }
}

/// Where a session's agent is in its turn (docs/SPEC.md §3).
public enum SessionState: Equatable, Sendable, CaseIterable {
    case working
    case waiting
    case needsPermission
    case needsAnswer
    case needsPlanApproval
    case idle
    case ended
}

/// One option of a question the agent asked.
public struct QuestionOption: Equatable, Sendable {
    public let id: String
    public let label: String

    public init(id: String, label: String) {
        self.id = id
        self.label = label
    }
}

/// A question the agent asked, with the options it offered.
public struct Question: Equatable, Sendable {
    public let prompt: String
    public let options: [QuestionOption]

    public init(prompt: String, options: [QuestionOption]) {
        self.prompt = prompt
        self.options = options
    }
}

/// A decision the agent is blocked on, answered through cmux Feed by `requestID`.
public enum PendingDecision: Equatable, Sendable {
    case permission(requestID: String, tool: String, input: String)
    case question(requestID: String, questions: [Question])
    case plan(requestID: String, plan: String)

    public var requestID: String {
        switch self {
        case let .permission(requestID, _, _), let .question(requestID, _), let .plan(requestID, _):
            requestID
        }
    }

    /// The state a session is in while this decision is open.
    public var state: SessionState {
        switch self {
        case .permission: .needsPermission
        case .question: .needsAnswer
        case .plan: .needsPlanApproval
        }
    }
}

/// Where an event sits in cmux's event stream, and when it happened.
///
/// Order comes from `seq`, never the clock: hooks, Feed and notifications stamp times from
/// different moments, so wall-clock order can disagree with the stream's. Bootstrap snapshots use
/// the stream position they were read at.
public struct Stamp: Equatable, Sendable {
    public let seq: UInt64
    public let time: Date

    public init(seq: UInt64, time: Date) {
        self.seq = seq
        self.time = time
    }
}

/// Identity details carried by every agent event; used to create a session on first sight.
public struct SessionContext: Equatable, Sendable {
    public let id: SessionID
    public let cwd: String
    public let workspaceID: String?
    public let surfaceID: String?

    public init(id: SessionID, cwd: String, workspaceID: String? = nil, surfaceID: String? = nil) {
        self.id = id
        self.cwd = cwd
        self.workspaceID = workspaceID
        self.surfaceID = surfaceID
    }
}

/// One agent session as Radar sees it.
public struct Session: Identifiable, Equatable, Sendable {
    public let id: SessionID
    public var agent: AgentKind
    /// The cmux tab title; falls back to the cwd's last path component.
    public var title: String
    public var cwd: String
    public var workspaceID: String?
    /// `nil` means Radar can't type into it: jump only.
    public var surfaceID: String?
    public var state: SessionState
    public var lastUserMessage: String?
    public var lastAgentMessage: String?
    public var summary: String?
    public var pending: PendingDecision?
    /// When the open decision arrived; Feed stops holding it after `Policy.pendingTimeout`.
    public var pendingSince: Date?
    public var updatedAt: Date
    /// The stream position of the last event applied: an event from earlier in the stream is stale.
    public var lastSeq: UInt64

    /// A new session seen for the first time, titled after its working directory.
    public init(context: SessionContext, state: SessionState, at stamp: Stamp) {
        id = context.id
        agent = AgentKind(sessionID: context.id)
        title = defaultTitle(cwd: context.cwd, id: context.id)
        cwd = context.cwd
        workspaceID = context.workspaceID
        surfaceID = context.surfaceID
        self.state = state
        updatedAt = stamp.time
        lastSeq = stamp.seq
    }
}

/// The cwd's last path component, or the session id when the cwd is empty or `/`.
public func defaultTitle(cwd: String, id: SessionID) -> String {
    cwd.split(separator: "/").last.map(String.init) ?? id.rawValue
}

/// Timing rules for the reducer and actions (docs/SPEC.md §3).
public struct Policy: Equatable, Sendable {
    /// A waiting session with no activity for this long becomes idle.
    public var idleAfter: TimeInterval
    /// An ended session is hidden this long after it ended.
    public var hideEndedAfter: TimeInterval
    /// cmux Feed holds a decision this long before the agent falls back to its terminal prompt.
    public var pendingTimeout: TimeInterval
    /// Feed replies stop this long before the timeout, so one in flight still arrives in time.
    public var replyMargin: TimeInterval

    public init(idleAfter: TimeInterval, hideEndedAfter: TimeInterval, pendingTimeout: TimeInterval, replyMargin: TimeInterval = 5) {
        self.idleAfter = idleAfter
        self.hideEndedAfter = hideEndedAfter
        self.pendingTimeout = pendingTimeout
        self.replyMargin = replyMargin
    }

    public static let standard = Policy(idleAfter: 2 * 60 * 60, hideEndedAfter: 10 * 60, pendingTimeout: 120, replyMargin: 5)
}
