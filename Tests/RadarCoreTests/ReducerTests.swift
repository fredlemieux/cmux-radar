// MUTATION-VERIFIED: killed 26/26 mutants on 2026-11-19 (Reducer.swift, across this file, ReducerDetailTests, ReducerOrderingTests and ReducerPropertyTests)
import Foundation
import PropertyBased
@testable import RadarCore
import Testing

private let api = SessionID("claude-api")

enum ReducerTests {
    struct WhenAPromptIsSubmitted {
        @Test func `creates an unseen session as working`() {
            let next = reduce(RadarState(), .promptSubmitted(context("claude-api"), stamp: stamp(0)))
            #expect(next.sessions[api]?.state == .working)
        }

        @Test func `titles a new session after its working directory`() {
            let next = reduce(RadarState(), .promptSubmitted(context("claude-api", cwd: "/Users/dev/code/billing"), stamp: stamp(0)))
            #expect(next.sessions[api]?.title == "billing")
        }

        @Test func `moves a waiting session to working`() {
            let next = reduce(radar(session("claude-api", .waiting)), .promptSubmitted(context("claude-api"), stamp: stamp(5)))
            #expect(next.sessions[api]?.state == .working)
        }

        @Test func `clears an open decision`() {
            let start = radar(session("claude-api", .needsPermission, pending: permission, pendingSince: epoch))
            let next = reduce(start, .promptSubmitted(context("claude-api"), stamp: stamp(5)))
            #expect(next.sessions[api]?.pending == nil)
        }

        @Test func `clears when the open decision arrived`() {
            let start = radar(session("claude-api", .needsPermission, pending: permission, pendingSince: epoch))
            let next = reduce(start, .promptSubmitted(context("claude-api"), stamp: stamp(5)))
            #expect(next.sessions[api]?.pendingSince == nil)
        }

        @Test func `records the event time`() {
            let next = reduce(radar(session("claude-api", .waiting)), .promptSubmitted(context("claude-api"), stamp: stamp(5)))
            #expect(next.sessions[api]?.updatedAt == at(5))
        }

        @Test func `revives an ended session, because a new prompt is a new turn`() {
            let next = reduce(radar(session("claude-api", .ended)), .promptSubmitted(context("claude-api"), stamp: stamp(5)))
            #expect(next.sessions[api]?.state == .working)
        }

        @Test func `ignores a prompt older than the last activity`() {
            let start = radar(session("claude-api", .waiting, updatedAt: at(60)))
            #expect(reduce(start, .promptSubmitted(context("claude-api"), stamp: stamp(5))) == start)
        }

        @Test func `never moves a session to another surface`() {
            let next = reduce(
                radar(session("claude-api", .waiting)),
                .promptSubmitted(context("claude-api", surface: "surface-7"), stamp: stamp(5)),
            )
            #expect(next.sessions[api]?.surfaceID == "surface-1")
        }

        @Test func `records the stream position`() {
            let next = reduce(radar(session("claude-api", .waiting)), .promptSubmitted(context("claude-api"), stamp: stamp(5, seq: 42)))
            #expect(next.sessions[api]?.lastSeq == 42)
        }

        @Test func `fills in a surface the session was missing`() {
            let start = radar(session("claude-api", .waiting, surface: nil))
            let next = reduce(start, .promptSubmitted(context("claude-api", surface: "surface-7"), stamp: stamp(5)))
            #expect(next.sessions[api]?.surfaceID == "surface-7")
        }

        @Test func `keeps the known surface when the event has none`() {
            let next = reduce(
                radar(session("claude-api", .waiting)),
                .promptSubmitted(context("claude-api", surface: nil), stamp: stamp(5)),
            )
            #expect(next.sessions[api]?.surfaceID == "surface-1")
        }

        @Test func `keeps the known cwd when the event has none`() {
            let next = reduce(radar(session("claude-api", .waiting)), .promptSubmitted(context("claude-api", cwd: ""), stamp: stamp(5)))
            #expect(next.sessions[api]?.cwd == "/Users/dev/code/api")
        }

        @Test func `takes a new cwd`() {
            let next = reduce(
                radar(session("claude-api", .waiting)),
                .promptSubmitted(context("claude-api", cwd: "/tmp/x"), stamp: stamp(5)),
            )
            #expect(next.sessions[api]?.cwd == "/tmp/x")
        }

        @Test func `keeps a title set from cmux`() {
            var titled = session("claude-api", .waiting)
            titled.title = "API tab"
            let next = reduce(radar(titled), .promptSubmitted(context("claude-api"), stamp: stamp(5)))
            #expect(next.sessions[api]?.title == "API tab")
        }
    }

    struct WhenAToolStarts {
        let open = radar(session("claude-api", .needsPermission, pending: permission, pendingSince: epoch))

        @Test func `moves a waiting session to working`() {
            let next = reduce(radar(session("claude-api", .waiting)), .toolStarted(context("claude-api"), stamp: stamp(5)))
            #expect(next.sessions[api]?.state == .working)
        }

        @Test func `creates an unseen session as working`() {
            #expect(reduce(RadarState(), .toolStarted(context("claude-api"), stamp: stamp(0))).sessions[api]?.state == .working)
        }

        @Test func `keeps an open decision, because a parallel tool can run while one is open`() {
            #expect(reduce(open, .toolStarted(context("claude-api"), stamp: stamp(5))).sessions[api]?.pending == permission)
        }

        @Test func `keeps the decision state while one is open`() {
            #expect(reduce(open, .toolStarted(context("claude-api"), stamp: stamp(5))).sessions[api]?.state == .needsPermission)
        }

        @Test func `records the activity`() {
            #expect(reduce(open, .toolStarted(context("claude-api"), stamp: stamp(5))).sessions[api]?.updatedAt == at(5))
        }

        @Test func `leaves an ended session ended`() {
            let start = radar(session("claude-api", .ended))
            #expect(reduce(start, .toolStarted(context("claude-api"), stamp: stamp(5))) == start)
        }
    }

    struct WhenADecisionIsRequested {
        @Test func `a permission request needs permission`() {
            let next = reduce(
                radar(session("claude-api", .working)),
                .decisionRequested(context("claude-api"), permission, stamp: stamp(5)),
            )
            #expect(next.sessions[api]?.state == .needsPermission)
        }

        @Test func `a question needs an answer`() {
            let next = reduce(radar(session("claude-api", .working)), .decisionRequested(context("claude-api"), question, stamp: stamp(5)))
            #expect(next.sessions[api]?.state == .needsAnswer)
        }

        @Test func `a plan needs approval`() {
            let next = reduce(radar(session("claude-api", .working)), .decisionRequested(context("claude-api"), plan, stamp: stamp(5)))
            #expect(next.sessions[api]?.state == .needsPlanApproval)
        }

        @Test func `holds the decision`() {
            let next = reduce(
                radar(session("claude-api", .working)),
                .decisionRequested(context("claude-api"), permission, stamp: stamp(5)),
            )
            #expect(next.sessions[api]?.pending == permission)
        }

        @Test func `records when the decision arrived`() {
            let next = reduce(
                radar(session("claude-api", .working)),
                .decisionRequested(context("claude-api"), permission, stamp: stamp(5)),
            )
            #expect(next.sessions[api]?.pendingSince == at(5))
        }

        @Test func `keeps the arrival time of a re-sent decision`() {
            let start = radar(session("claude-api", .needsPermission, pending: permission, pendingSince: epoch))
            let next = reduce(start, .decisionRequested(context("claude-api"), permission, stamp: stamp(30)))
            #expect(next.sessions[api]?.pendingSince == epoch)
        }

        @Test func `a new decision replaces the open one with its own arrival time`() {
            let start = radar(session("claude-api", .needsPermission, pending: permission, pendingSince: epoch))
            let next = reduce(start, .decisionRequested(context("claude-api"), question, stamp: stamp(30)))
            #expect(next.sessions[api]?.pendingSince == at(30))
        }

        @Test func `leaves an ended session ended`() {
            let start = radar(session("claude-api", .ended))
            #expect(reduce(start, .decisionRequested(context("claude-api"), question, stamp: stamp(5))) == start)
        }

        @Test func `creates an unseen session already waiting on the decision`() {
            let next = reduce(RadarState(), .decisionRequested(context("claude-api"), question, stamp: stamp(0)))
            #expect(next.sessions[api]?.state == .needsAnswer)
        }
    }

    struct WhenADecisionIsResolved {
        let open = radar(session("claude-api", .needsPermission, pending: permission, pendingSince: epoch))

        @Test func `goes back to working`() {
            let next = reduce(open, .decisionResolved(requestID: "req-1", stamp: stamp(5)))
            #expect(next.sessions[api]?.state == .working)
        }

        @Test func `drops the decision`() {
            let next = reduce(open, .decisionResolved(requestID: "req-1", stamp: stamp(5)))
            #expect(next.sessions[api]?.pending == nil)
        }

        @Test func `drops when the decision arrived`() {
            let next = reduce(open, .decisionResolved(requestID: "req-1", stamp: stamp(5)))
            #expect(next.sessions[api]?.pendingSince == nil)
        }

        @Test func `records the event time`() {
            let next = reduce(open, .decisionResolved(requestID: "req-1", stamp: stamp(5)))
            #expect(next.sessions[api]?.updatedAt == at(5))
        }

        @Test func `finds the session by request id alone`() {
            let start = radar(
                session("claude-web", .waiting),
                session("claude-api", .needsPermission, pending: permission, pendingSince: epoch),
            )
            #expect(reduce(start, .decisionResolved(requestID: "req-1", stamp: stamp(5))).sessions[api]?.state == .working)
        }

        @Test func `a late resolution does not move the activity time back`() {
            var later = session("claude-api", .needsPermission, pending: permission, pendingSince: epoch)
            later.updatedAt = at(60)
            let next = reduce(radar(later), .decisionResolved(requestID: "req-1", stamp: stamp(5)))
            #expect(next.sessions[api]?.updatedAt == at(60))
        }

        @Test func `ignores another request id`() {
            let next = reduce(open, .decisionResolved(requestID: "req-old", stamp: stamp(5)))
            #expect(next == open)
        }

        @Test func `ignores an unseen session`() {
            let next = reduce(RadarState(), .decisionResolved(requestID: "req-1", stamp: stamp(0)))
            #expect(next.sessions.isEmpty)
        }
    }
}
