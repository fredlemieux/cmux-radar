// MUTATION-VERIFIED: killed 10/10 mutants on 2026-11-19 (Reducer.swift, with ReducerTests)
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

struct ReducerPropertyTests {
    /// Events that name one session.
    static let targeted: [RadarEvent] = [
        .promptSubmitted(context("claude-api"), time: at(5)),
        .toolStarted(context("claude-api"), time: at(5)),
        .decisionRequested(context("claude-api"), question, time: at(5)),
        .decisionResolved(api, requestID: "req-1", time: at(5)),
        .stopped(context("claude-api"), time: at(5)),
        .sessionEnded(api, time: at(5)),
        .titleChanged(api, title: "API tab"),
        .textResolved(api, lastUserMessage: "a", lastAgentMessage: "b"),
    ]

    @Test func `an event for one session never changes another`() async {
        await propertyCheck(input: anySession, Gen.element(of: Self.targeted).compactMap(\.self)) { other, event in
            var bystander = Session(context: context("claude-web", surface: "surface-9"), state: other.state, at: epoch)
            bystander.pending = other.pending
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
}
