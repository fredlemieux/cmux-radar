public import Foundation

/// How a permission is granted.
public enum PermissionScope: Equatable, Sendable {
    case once
    case always
}

/// Something the user can do to a session (docs/SPEC.md §4).
public enum SessionAction: Equatable, Sendable {
    case reply(String)
    case allow(PermissionScope)
    case deny(message: String?)
    case answer(optionIDs: [String])
    case approvePlan
    case rejectPlan(feedback: String?)
    case jump
}

/// Whether `action` may be sent to `session` right now. Callers re-check immediately before
/// sending, because the session can change between showing a control and using it.
public func isAllowed(_ action: SessionAction, on session: Session, now: Date, policy: Policy = .standard) -> Bool {
    switch action {
    case .reply: canType(into: session)
    case .allow, .deny: canDecide(session, in: .needsPermission, now: now, policy: policy)
    case .answer: canDecide(session, in: .needsAnswer, now: now, policy: policy)
    case .approvePlan, .rejectPlan: canDecide(session, in: .needsPlanApproval, now: now, policy: policy)
    case .jump: true
    }
}

/// Typing lands in the terminal, so only between turns and only with a surface to type into.
/// Never while working: the text would arrive mid-turn.
func canType(into session: Session) -> Bool {
    let betweenTurns = session.state == .waiting || session.state == .idle
    return betweenTurns && session.surfaceID != nil
}

/// A Feed reply needs the matching open decision, still held by Feed.
func canDecide(_ session: Session, in state: SessionState, now: Date, policy: Policy) -> Bool {
    session.state == state && session.pending != nil && !isPendingExpired(session, now: now, policy: policy)
}

/// Feed has let go of the decision; the agent is asking in its terminal instead, so jump there.
public func isPendingExpired(_ session: Session, now: Date, policy: Policy = .standard) -> Bool {
    guard let since = session.pendingSince else {
        return false
    }
    return now.timeIntervalSince(since) > policy.pendingTimeout
}
