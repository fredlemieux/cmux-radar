// MUTATION-VERIFIED: n/a — shared fixtures
import Foundation
import PropertyBased
@testable import RadarCore

let epoch = Date(timeIntervalSinceReferenceDate: 800_000_000)

func at(_ seconds: TimeInterval) -> Date {
    epoch.addingTimeInterval(seconds)
}

func context(_ id: String, cwd: String = "/Users/dev/code/api", surface: String? = "surface-1") -> SessionContext {
    SessionContext(id: SessionID(id), cwd: cwd, workspaceID: "workspace-1", surfaceID: surface)
}

func session(
    _ id: String,
    _ state: SessionState,
    surface: String? = "surface-1",
    pending: PendingDecision? = nil,
    pendingSince: Date? = nil,
    updatedAt: Date = epoch,
) -> Session {
    var session = Session(context: context(id, surface: surface), state: state, at: updatedAt)
    session.pending = pending
    session.pendingSince = pendingSince
    return session
}

func radar(_ sessions: Session...) -> RadarState {
    RadarState(sessions: Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) }))
}

let permission = PendingDecision.permission(requestID: "req-1", tool: "Bash", input: "pnpm db:migrate")
let question = PendingDecision.question(
    requestID: "req-2",
    questions: [Question(prompt: "Ship it?", options: [QuestionOption(id: "a", label: "Yes")])],
)
let plan = PendingDecision.plan(requestID: "req-3", plan: "1. Migrate\n2. Backfill")

/// A session in any state, with a decision exactly when the state needs one.
let anySession = Gen.element(of: SessionState.allCases)
    .compactMap(\.self)
    .map { state in
        switch state {
        case .needsPermission: session("claude-api", state, pending: permission, pendingSince: epoch)
        case .needsAnswer: session("claude-api", state, pending: question, pendingSince: epoch)
        case .needsPlanApproval: session("claude-api", state, pending: plan, pendingSince: epoch)
        default: session("claude-api", state)
        }
    }
