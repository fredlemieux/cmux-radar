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
/// Events can arrive late or be replayed (bootstrap, resume gaps), so an event from earlier in
/// cmux's stream than the last one applied to a session never changes it.
public func reduce(_ state: RadarState, _ event: RadarEvent, policy: Policy = .standard) -> RadarState {
    var next = state
    switch event {
    case .promptSubmitted, .toolStarted, .decisionRequested, .stopped:
        next = applyTurnEvent(next, event)
    case let .decisionResolved(requestID, stamp):
        next.sessions = next.sessions.mapValues { resolveDecision($0, .request(requestID), at: stamp) }
    case let .decisionsListed(open, stamp):
        next.sessions = next.sessions.mapValues { isStale(stamp, for: $0) ? $0 : resolveDecision($0, .allExcept(open), at: stamp) }
    case let .waitingNotification(surfaceID, stamp):
        next.sessions = next.sessions.mapValues { markWaiting($0, onSurface: surfaceID, at: stamp) }
    case let .sessionEnded(id, stamp):
        next.sessions[id] = next.sessions[id].map { isStale(stamp, for: $0) ? $0 : end($0, at: stamp) }
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
    case let .promptSubmitted(context, stamp):
        next.sessions[context.id] = update(state.sessions[context.id], context, at: stamp, rule: .revives) { startTurn($0, at: stamp) }
    case let .toolStarted(context, stamp):
        next.sessions[context.id] = update(state.sessions[context.id], context, at: stamp, rule: .creates) { runTool($0, at: stamp) }
    case let .decisionRequested(context, decision, stamp):
        next.sessions[context.id] = update(state.sessions[context.id], context, at: stamp, rule: .creates) {
            openDecision($0, decision, at: stamp)
        }
    case let .stopped(context, stamp):
        next
            .sessions[context.id] = update(state.sessions[context.id], context, at: stamp, rule: .existingOnly) { finishTurn($0, at: stamp)
            }
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
    at stamp: Stamp,
    rule: UpdateRule,
    _ change: (Session) -> Session,
) -> Session? {
    guard let existing else {
        return firstSight(context, at: stamp, rule: rule, change)
    }
    guard !isStale(stamp, for: existing), existing.state != .ended || rule == .revives else {
        return existing
    }
    return change(merged(existing, with: context, resumed: existing.state == .ended))
}

/// A session Radar hasn't seen: created unless the rule only touches known sessions.
private func firstSight(_ context: SessionContext, at stamp: Stamp, rule: UpdateRule, _ change: (Session) -> Session) -> Session? {
    rule == .existingOnly ? nil : change(Session(context: context, state: .working, at: stamp))
}

/// From earlier in the stream than the last event applied: a replay or a late delivery.
func isStale(_ stamp: Stamp, for session: Session) -> Bool {
    stamp.seq < session.lastSeq
}

/// Strictly later in the stream than the last event applied. A bootstrap snapshot shares the
/// position it was read at, so it never counts as newer than the live event at that position.
func isNewer(_ stamp: Stamp, than session: Session) -> Bool {
    stamp.seq > session.lastSeq
}

/// Records an applied event: its stream position and when it happened.
func touched(_ session: Session, at stamp: Stamp) -> Session {
    var updated = session
    updated.lastSeq = max(stamp.seq, session.lastSeq)
    updated.updatedAt = max(stamp.time, session.updatedAt)
    return updated
}

/// Fills context the session lacked (cmux sometimes sends a null surface). A known surface or
/// workspace is never replaced by a live session's events: typing into the wrong tab is worse than
/// not typing. A resumed session (a prompt after it ended) takes the surface it resumed in.
func merged(_ session: Session, with context: SessionContext, resumed: Bool) -> Session {
    var updated = session
    updated.surfaceID = resumed ? context.surfaceID : session.surfaceID ?? context.surfaceID
    updated.workspaceID = resumed ? context.workspaceID : session.workspaceID ?? context.workspaceID
    updated.cwd = context.cwd.isEmpty ? session.cwd : context.cwd
    return updated
}

/// The user sent a prompt: a new turn, so any earlier decision is moot.
private func startTurn(_ session: Session, at stamp: Stamp) -> Session {
    var updated = session
    updated.state = .working
    updated.pending = nil
    updated.pendingSince = nil
    return touched(updated, at: stamp)
}

/// A tool started. A parallel tool call or subagent can run while a decision is open, so an open
/// decision stays open: the agent is still blocked on it.
private func runTool(_ session: Session, at stamp: Stamp) -> Session {
    var updated = session
    if session.pending == nil {
        updated.state = .working
    }
    return touched(updated, at: stamp)
}

/// A re-sent copy of the open decision (a bootstrap redo) keeps its original arrival time, so the
/// Feed timeout isn't restarted.
private func openDecision(_ session: Session, _ decision: PendingDecision, at stamp: Stamp) -> Session {
    var updated = session
    let resent = session.pending?.requestID == decision.requestID
    updated.state = decision.state
    updated.pending = decision
    updated.pendingSince = resent ? session.pendingSince : stamp.time
    return touched(updated, at: stamp)
}

/// Which open decisions an event closes.
enum Closing {
    /// A Feed resolution: only the decision with that request id.
    case request(String)
    /// A `feed.list` snapshot: every decision Feed no longer holds.
    case allExcept(Set<String>)
}

func closes(_ closing: Closing, _ requestID: String) -> Bool {
    switch closing {
    case let .request(id):
        return requestID == id
    case let .allExcept(open):
        let stillHeld = open.contains(requestID)
        return !stillHeld
    }
}

/// Closes the open decision if the event says it's over; any other decision is left alone.
private func resolveDecision(_ session: Session, _ closing: Closing, at stamp: Stamp) -> Session {
    guard let pending = session.pending, closes(closing, pending.requestID) else {
        return session
    }
    var updated = session
    updated.state = .working
    updated.pending = nil
    updated.pendingSince = nil
    return touched(updated, at: stamp)
}

/// The turn is over, so nothing can still be pending.
private func finishTurn(_ session: Session, at stamp: Stamp) -> Session {
    var updated = session
    updated.state = .waiting
    updated.pending = nil
    updated.pendingSince = nil
    return touched(updated, at: stamp)
}

/// Only a working session on that surface flips, and only for a fresh notification: it never
/// overrides a decision, and a replayed one never undoes a newer turn.
private func markWaiting(_ session: Session, onSurface surfaceID: String, at stamp: Stamp) -> Session {
    guard session.surfaceID == surfaceID, session.state == .working, isNewer(stamp, than: session) else {
        return session
    }
    var updated = session
    updated.state = .waiting
    return touched(updated, at: stamp)
}

private func end(_ session: Session, at stamp: Stamp) -> Session {
    var updated = session
    updated.state = .ended
    updated.pending = nil
    updated.pendingSince = nil
    return touched(updated, at: stamp)
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
