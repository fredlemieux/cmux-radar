public import Foundation

/// How a permission is granted.
public enum PermissionScope: Equatable, Sendable {
    case once
    case always
}

/// Something the user can do to a session (docs/SPEC.md §4). A decision names the request it
/// answers, so it can never land on a different decision that replaced the one on screen.
public enum SessionAction: Equatable, Sendable {
    case reply(String)
    case allow(PermissionScope, requestID: String)
    case deny(message: String?, requestID: String)
    case answer(optionIDs: [String], requestID: String)
    case approvePlan(requestID: String)
    case rejectPlan(feedback: String?, requestID: String)
    case jump
}

/// Whether `action` may be sent to `session` right now. Callers re-check immediately before
/// sending, because the session can change between showing a control and using it.
public func isAllowed(_ action: SessionAction, on session: Session, now: Date, policy: Policy = .standard) -> Bool {
    switch action {
    case .reply:
        canType(into: session)
    case let .allow(_, requestID), let .deny(_, requestID):
        canDecide(requestID, on: session, in: .needsPermission, now: now, policy: policy)
    case let .answer(_, requestID):
        canDecide(requestID, on: session, in: .needsAnswer, now: now, policy: policy)
    case let .approvePlan(requestID), let .rejectPlan(_, requestID):
        canDecide(requestID, on: session, in: .needsPlanApproval, now: now, policy: policy)
    case .jump:
        true
    }
}

/// Typing lands in the terminal, so only between turns and only with a surface to type into.
/// Never while working: the text would arrive mid-turn.
func canType(into session: Session) -> Bool {
    let betweenTurns = session.state == .waiting || session.state == .idle
    return betweenTurns && session.surfaceID != nil
}

/// A Feed reply needs that very decision to be the open one, in the matching state, and still
/// held by Feed with time to spare.
func canDecide(_ requestID: String, on session: Session, in state: SessionState, now: Date, policy: Policy) -> Bool {
    session.state == state && session.pending?.requestID == requestID && !isPendingExpired(session, now: now, policy: policy)
}

/// Feed has let go of the decision, or will before a reply could arrive; the agent is asking in
/// its terminal instead, so jump there.
public func isPendingExpired(_ session: Session, now: Date, policy: Policy = .standard) -> Bool {
    guard let since = session.pendingSince else {
        return false
    }
    return now.timeIntervalSince(since) > policy.pendingTimeout - policy.replyMargin
}
