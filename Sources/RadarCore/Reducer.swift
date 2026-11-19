internal import Foundation

/// Every session Radar knows about, keyed by id.
public struct RadarState: Equatable, Sendable {
    public var sessions: [SessionID: Session]

    public init(sessions: [SessionID: Session] = [:]) {
        self.sessions = sessions
    }
}

/// The pure state transition for one event (docs/SPEC.md §3, "State transitions").
public func reduce(_ state: RadarState, _ event: RadarEvent, policy: Policy = .standard) -> RadarState {
    var next = state
    switch event {
    case let .promptSubmitted(context, time), let .toolStarted(context, time):
        next.sessions[context.id] = startWorking(next.sessions[context.id], context: context, at: time)
    case let .decisionRequested(context, decision, time):
        next.sessions[context.id] = openDecision(next.sessions[context.id], decision, context: context, at: time)
    case let .decisionResolved(id, requestID, time):
        next.sessions[id] = next.sessions[id].map { resolveDecision($0, requestID: requestID, at: time) }
    case let .stopped(context, time):
        next.sessions[context.id] = finishTurn(next.sessions[context.id], context: context, at: time)
    case let .waitingNotification(surfaceID, time):
        next.sessions = next.sessions.mapValues { markWaiting($0, onSurface: surfaceID, at: time) }
    case let .sessionEnded(id, time):
        next.sessions[id] = next.sessions[id].map { end($0, at: time) }
    case let .titleChanged(id, _), let .textResolved(id, _, _):
        next.sessions[id] = next.sessions[id].map { annotate($0, with: event) }
    case let .tick(now):
        next.sessions = age(next.sessions, now: now, policy: policy)
    }
    return next
}

private func startWorking(_ session: Session?, context: SessionContext, at time: Date) -> Session {
    var updated = session ?? Session(context: context, state: .working, at: time)
    updated.state = .working
    updated.pending = nil
    updated.pendingSince = nil
    updated.updatedAt = time
    return updated
}

private func openDecision(_ session: Session?, _ decision: PendingDecision, context: SessionContext, at time: Date) -> Session {
    var updated = session ?? Session(context: context, state: decision.state, at: time)
    updated.state = decision.state
    updated.pending = decision
    updated.pendingSince = time
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
    updated.updatedAt = time
    return updated
}

/// The turn is over, so nothing can still be pending.
private func finishTurn(_ session: Session?, context: SessionContext, at time: Date) -> Session {
    var updated = session ?? Session(context: context, state: .waiting, at: time)
    updated.state = .waiting
    updated.pending = nil
    updated.pendingSince = nil
    updated.updatedAt = time
    return updated
}

/// Only a working session on that surface flips: the notification never overrides a decision.
private func markWaiting(_ session: Session, onSurface surfaceID: String, at time: Date) -> Session {
    guard session.surfaceID == surfaceID, session.state == .working else {
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
