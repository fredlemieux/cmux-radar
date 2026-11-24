// MUTATION-VERIFIED: see ReducerTests.swift (same subject, Reducer.swift; counted once there)
import Foundation
import PropertyBased
@testable import RadarCore
import Testing

private let api = SessionID("claude-api")
private let web = SessionID("claude-web")

/// A session waits on a decision exactly when it holds one, and the decision matches the state.
private func holdsDecisionConsistently(_ session: Session) -> Bool {
    let needsDecision = [SessionState.needsPermission, .needsAnswer, .needsPlanApproval].contains(session.state)
    guard let pending = session.pending else {
        return !needsDecision
    }
    return pending.state == session.state
}

/// Events guarded by stream order. Resolutions match a unique request id and text or title
/// carry no stream position, so those apply whenever they arrive.
private func isOrderedByStream(_ event: RadarEvent) -> Bool {
    switch event {
    case .promptSubmitted, .toolStarted, .decisionRequested, .stopped, .waitingNotification, .sessionEnded: true
    default: false
    }
}

private func renumbered(_ decision: PendingDecision, requestID: String) -> PendingDecision {
    switch decision {
    case let .permission(_, tool, input): .permission(requestID: requestID, tool: tool, input: input)
    case let .question(_, questions): .question(requestID: requestID, questions: questions)
    case let .plan(_, plan): .plan(requestID: requestID, plan: plan)
    }
}

struct ReducerPropertyTests {
    /// Events that name one session.
    static let targeted: [RadarEvent] = [
        .promptSubmitted(context("claude-api"), stamp: stamp(5)),
        .toolStarted(context("claude-api"), stamp: stamp(5)),
        .decisionRequested(context("claude-api"), question, stamp: stamp(5)),
        .decisionResolved(requestID: "req-1", stamp: stamp(5)),
        .stopped(context("claude-api"), stamp: stamp(5)),
        .waitingNotification(surfaceID: "surface-1", stamp: stamp(5)),
        .sessionEnded(api, stamp: stamp(5)),
        .titleChanged(api, title: "API tab"),
        .textResolved(api, lastUserMessage: "a", lastAgentMessage: "b"),
    ]

    @Test func `an event for one session never changes another`() async {
        await propertyCheck(input: anySession, Gen.element(of: Self.targeted).compactMap(\.self)) { other, event in
            var bystander = Session(context: context("claude-web", surface: "surface-9"), state: other.state, at: stamp(0))
            bystander.pending = other.pending.map { renumbered($0, requestID: "req-web") } // Feed ids are unique.
            bystander.pendingSince = other.pendingSince
            #expect(reduce(radar(bystander), event).sessions[web] == bystander)
        }
    }

    @Test func `only the clock removes sessions`() async {
        await propertyCheck(input: anySession, Gen.element(of: Self.targeted).compactMap(\.self)) { start, event in
            let before = radar(start)
            #expect(reduce(before, event).sessions.count >= before.sessions.count)
        }
    }

    @Test func `the clock never adds sessions`() async {
        await propertyCheck(input: anySession, Gen.double(in: 0 ... 100_000)) { start, seconds in
            #expect(reduce(radar(start), .tick(at(seconds))).sessions.count <= 1)
        }
    }

    @Test func `a session always holds a decision exactly when its state needs one`() async {
        await propertyCheck(input: anySession, Gen.element(of: Self.targeted).compactMap(\.self)) { start, event in
            #expect(reduce(radar(start), event).sessions.values.allSatisfy(holdsDecisionConsistently))
        }
    }

    /// A resolution is matched by its unique request id, so it applies whenever it arrives.
    static let timed = targeted.filter(isOrderedByStream)

    @Test func `an event from earlier in the stream never changes a session`() async {
        await propertyCheck(input: anySession, Gen.element(of: Self.timed).compactMap(\.self)) { start, event in
            var recent = start
            recent.lastSeq = 1000
            #expect(reduce(radar(recent), event).sessions[api] == recent)
        }
    }
}
