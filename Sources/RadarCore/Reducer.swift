internal import Foundation

/// Every session Radar knows about, keyed by id.
public struct RadarState: Equatable, Sendable {
    public var sessions: [SessionID: Session]

    public init(sessions: [SessionID: Session] = [:]) {
        self.sessions = sessions
    }
}

/// The pure state transition for one event (docs/SPEC.md §3, "State transitions").
///
/// Events can arrive late or be replayed (bootstrap, resume gaps), so an event older than a
/// session's last activity never changes it.
public func reduce(_ state: RadarState, _ event: RadarEvent, policy: Policy = .standard) -> RadarState {
    var next = state
    switch event {
    case .promptSubmitted, .toolStarted, .decisionRequested, .stopped:
        next = applyTurnEvent(next, event)
    case let .decisionResolved(requestID, time):
        next.sessions = next.sessions.mapValues { resolveDecision($0, requestID: requestID, at: time) }
    case let .waitingNotification(surfaceID, time):
        next.sessions = next.sessions.mapValues { markWaiting($0, onSurface: surfaceID, at: time) }
    case let .sessionEnded(id, time):
        next.sessions[id] = next.sessions[id].map { isStale(time, for: $0) ? $0 : end($0, at: time) }
    case let .titleChanged(id, _), let .textResolved(id, _, _):
        next.sessions[id] = next.sessions[id].map { annotate($0, with: event) }
    case let .tick(now):
        next.sessions = age(next.sessions, now: now, policy: policy)
    }
    return next
}

/// Prompt, tool, decision and stop: the events that carry a session's context.
private func applyTurnEvent(_ state: RadarState, _ event: RadarEvent) -> RadarState {
    var next = state
    switch event {
    case let .promptSubmitted(context, time):
        next.sessions[context.id] = update(state.sessions[context.id], context, at: time, rule: .revives) { startTurn($0, at: time) }
    case let .toolStarted(context, time):
        next.sessions[context.id] = update(state.sessions[context.id], context, at: time, rule: .creates) { runTool($0, at: time) }
    case let .decisionRequested(context, decision, time):
        next.sessions[context.id] = update(state.sessions[context.id], context, at: time, rule: .creates) {
            openDecision($0, decision, at: time)
        }
    case let .stopped(context, time):
        next.sessions[context.id] = update(state.sessions[context.id], context, at: time, rule: .existingOnly) { finishTurn($0, at: time) }
    default:
        break
    }
    return next
}

/// How an agent event treats a session Radar hasn't seen, or one that has ended.
enum UpdateRule {
    /// Creates an unseen session and revives an ended one: a new prompt is a new turn.
    case revives
    /// Creates an unseen session; leaves an ended one alone.
    case creates
    /// Only changes a live session Radar already knows (a late Stop must not make a ghost card).
    case existingOnly
}

/// Applies `change` to the session `context` names, following `rule`. Newer context (a surface
/// that was missing, a moved cwd) is merged in first.
private func update(
    _ existing: Session?,
    _ context: SessionContext,
    at time: Date,
    rule: UpdateRule,
    _ change: (Session) -> Session,
) -> Session? {
    guard let existing else {
        return firstSight(context, at: time, rule: rule, change)
    }
    guard !isStale(time, for: existing), existing.state != .ended || rule == .revives else {
        return existing
    }
    return change(merged(existing, with: context))
}

/// A session Radar hasn't seen: created unless the rule only touches known sessions.
private func firstSight(_ context: SessionContext, at time: Date, rule: UpdateRule, _ change: (Session) -> Session) -> Session? {
    rule == .existingOnly ? nil : change(Session(context: context, state: .working, at: time))
}

/// Older than the session's last activity: a replay or a late delivery.
func isStale(_ time: Date, for session: Session) -> Bool {
    time < session.updatedAt
}

/// Keeps what the session knew when the event leaves it out (cmux sometimes sends a null surface).
func merged(_ session: Session, with context: SessionContext) -> Session {
    var updated = session
    updated.surfaceID = context.surfaceID ?? session.surfaceID
    updated.workspaceID = context.workspaceID ?? session.workspaceID
    updated.cwd = context.cwd.isEmpty ? session.cwd : context.cwd
    return updated
}

/// The user sent a prompt: a new turn, so any earlier decision is moot.
private func startTurn(_ session: Session, at time: Date) -> Session {
    var updated = session
    updated.state = .working
    updated.pending = nil
    updated.pendingSince = nil
    updated.updatedAt = time
    return updated
}

/// A tool started. A parallel tool call or subagent can run while a decision is open, so an open
/// decision stays open: the agent is still blocked on it.
private func runTool(_ session: Session, at time: Date) -> Session {
    var updated = session
    if session.pending == nil {
        updated.state = .working
    }
    updated.updatedAt = time
    return updated
}

/// A re-sent copy of the open decision (a bootstrap redo) keeps its original arrival time, so the
/// Feed timeout isn't restarted.
private func openDecision(_ session: Session, _ decision: PendingDecision, at time: Date) -> Session {
    var updated = session
    let resent = session.pending?.requestID == decision.requestID
    updated.state = decision.state
    updated.pending = decision
    updated.pendingSince = resent ? session.pendingSince : time
    updated.updatedAt = time
    return updated
}

/// Only the open decision's own resolution closes it; a stale or foreign request id is ignored.
private func resolveDecision(_ session: Session, requestID: String, at time: Date) -> Session {
    guard session.pending?.requestID == requestID else {
        return session
    }
    var updated = session
    updated.state = .working
    updated.pending = nil
    updated.pendingSince = nil
    updated.updatedAt = max(time, session.updatedAt)
    return updated
}

/// The turn is over, so nothing can still be pending.
private func finishTurn(_ session: Session, at time: Date) -> Session {
    var updated = session
    updated.state = .waiting
    updated.pending = nil
    updated.pendingSince = nil
    updated.updatedAt = time
    return updated
}

/// Only a working session on that surface flips, and only for a fresh notification: it never
/// overrides a decision, and a replayed one never undoes a newer turn.
private func markWaiting(_ session: Session, onSurface surfaceID: String, at time: Date) -> Session {
    guard session.surfaceID == surfaceID, session.state == .working, !isStale(time, for: session) else {
        return session
    }
    var updated = session
    updated.state = .waiting
    updated.updatedAt = time
    return updated
}

private func end(_ session: Session, at time: Date) -> Session {
    var updated = session
    updated.state = .ended
    updated.pending = nil
    updated.pendingSince = nil
    updated.updatedAt = time
    return updated
}

/// Title and text change what a session shows, never its state or activity time.
private func annotate(_ session: Session, with event: RadarEvent) -> Session {
    var updated = session
    switch event {
    case let .titleChanged(_, title):
        updated.title = title
    case let .textResolved(_, user, agent):
        updated.lastUserMessage = user ?? session.lastUserMessage
        updated.lastAgentMessage = agent ?? session.lastAgentMessage
    default:
        break
    }
    return updated
}

private func age(_ sessions: [SessionID: Session], now: Date, policy: Policy) -> [SessionID: Session] {
    sessions
        .filter { !isLongEnded($0.value, now: now, policy: policy) }
        .mapValues { goesIdle($0, now: now, policy: policy) ? withState($0, .idle) : $0 }
}

/// Ended for longer than `hideEndedAfter`.
func isLongEnded(_ session: Session, now: Date, policy: Policy) -> Bool {
    session.state == .ended && now.timeIntervalSince(session.updatedAt) > policy.hideEndedAfter
}

/// Waiting with no activity for longer than `idleAfter`.
func goesIdle(_ session: Session, now: Date, policy: Policy) -> Bool {
    session.state == .waiting && now.timeIntervalSince(session.updatedAt) > policy.idleAfter
}

/// Ageing keeps `updatedAt`: it records the last activity, not the last state change.
private func withState(_ session: Session, _ state: SessionState) -> Session {
    var updated = session
    updated.state = state
    return updated
}
