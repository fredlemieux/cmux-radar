// MUTATION-VERIFIED: killed 10/10 mutants on 2026-11-19 (Reducer.swift, with ReducerDetailTests and ReducerPropertyTests)
import Foundation
import PropertyBased
@testable import RadarCore
import Testing

private let api = SessionID("claude-api")

enum ReducerTests {
    struct WhenAPromptIsSubmitted {
        @Test func `creates an unseen session as working`() {
            let next = reduce(RadarState(), .promptSubmitted(context("claude-api"), time: epoch))
            #expect(next.sessions[api]?.state == .working)
        }

        @Test func `titles a new session after its working directory`() {
            let next = reduce(RadarState(), .promptSubmitted(context("claude-api", cwd: "/Users/dev/code/billing"), time: epoch))
            #expect(next.sessions[api]?.title == "billing")
        }

        @Test func `moves a waiting session to working`() {
            let next = reduce(radar(session("claude-api", .waiting)), .promptSubmitted(context("claude-api"), time: at(5)))
            #expect(next.sessions[api]?.state == .working)
        }

        @Test func `clears an open decision`() {
            let start = radar(session("claude-api", .needsPermission, pending: permission, pendingSince: epoch))
            let next = reduce(start, .promptSubmitted(context("claude-api"), time: at(5)))
            #expect(next.sessions[api]?.pending == nil)
        }

        @Test func `clears when the open decision arrived`() {
            let start = radar(session("claude-api", .needsPermission, pending: permission, pendingSince: epoch))
            let next = reduce(start, .promptSubmitted(context("claude-api"), time: at(5)))
            #expect(next.sessions[api]?.pendingSince == nil)
        }

        @Test func `records the event time`() {
            let next = reduce(radar(session("claude-api", .waiting)), .promptSubmitted(context("claude-api"), time: at(5)))
            #expect(next.sessions[api]?.updatedAt == at(5))
        }

        @Test func `keeps a title set from cmux`() {
            var titled = session("claude-api", .waiting)
            titled.title = "API tab"
            let next = reduce(radar(titled), .promptSubmitted(context("claude-api"), time: at(5)))
            #expect(next.sessions[api]?.title == "API tab")
        }
    }

    struct WhenAToolStarts {
        @Test func `moves a waiting session to working`() {
            let next = reduce(radar(session("claude-api", .waiting)), .toolStarted(context("claude-api"), time: at(5)))
            #expect(next.sessions[api]?.state == .working)
        }
    }

    struct WhenADecisionIsRequested {
        @Test func `a permission request needs permission`() {
            let next = reduce(radar(session("claude-api", .working)), .decisionRequested(context("claude-api"), permission, time: at(5)))
            #expect(next.sessions[api]?.state == .needsPermission)
        }

        @Test func `a question needs an answer`() {
            let next = reduce(radar(session("claude-api", .working)), .decisionRequested(context("claude-api"), question, time: at(5)))
            #expect(next.sessions[api]?.state == .needsAnswer)
        }

        @Test func `a plan needs approval`() {
            let next = reduce(radar(session("claude-api", .working)), .decisionRequested(context("claude-api"), plan, time: at(5)))
            #expect(next.sessions[api]?.state == .needsPlanApproval)
        }

        @Test func `holds the decision`() {
            let next = reduce(radar(session("claude-api", .working)), .decisionRequested(context("claude-api"), permission, time: at(5)))
            #expect(next.sessions[api]?.pending == permission)
        }

        @Test func `records when the decision arrived`() {
            let next = reduce(radar(session("claude-api", .working)), .decisionRequested(context("claude-api"), permission, time: at(5)))
            #expect(next.sessions[api]?.pendingSince == at(5))
        }

        @Test func `creates an unseen session already waiting on the decision`() {
            let next = reduce(RadarState(), .decisionRequested(context("claude-api"), question, time: epoch))
            #expect(next.sessions[api]?.state == .needsAnswer)
        }
    }

    struct WhenADecisionIsResolved {
        let open = radar(session("claude-api", .needsPermission, pending: permission, pendingSince: epoch))

        @Test func `goes back to working`() {
            let next = reduce(open, .decisionResolved(api, requestID: "req-1", time: at(5)))
            #expect(next.sessions[api]?.state == .working)
        }

        @Test func `drops the decision`() {
            let next = reduce(open, .decisionResolved(api, requestID: "req-1", time: at(5)))
            #expect(next.sessions[api]?.pending == nil)
        }

        @Test func `drops when the decision arrived`() {
            let next = reduce(open, .decisionResolved(api, requestID: "req-1", time: at(5)))
            #expect(next.sessions[api]?.pendingSince == nil)
        }

        @Test func `records the event time`() {
            let next = reduce(open, .decisionResolved(api, requestID: "req-1", time: at(5)))
            #expect(next.sessions[api]?.updatedAt == at(5))
        }

        @Test func `ignores another request id`() {
            let next = reduce(open, .decisionResolved(api, requestID: "req-old", time: at(5)))
            #expect(next == open)
        }

        @Test func `ignores an unseen session`() {
            let next = reduce(RadarState(), .decisionResolved(api, requestID: "req-1", time: epoch))
            #expect(next.sessions.isEmpty)
        }
    }

    struct WhenTheAgentStops {
        @Test func `waits for the user`() {
            let next = reduce(radar(session("claude-api", .working)), .stopped(context("claude-api"), time: at(5)))
            #expect(next.sessions[api]?.state == .waiting)
        }

        @Test func `drops any decision`() {
            let start = radar(session("claude-api", .needsAnswer, pending: question, pendingSince: epoch))
            let next = reduce(start, .stopped(context("claude-api"), time: at(5)))
            #expect(next.sessions[api]?.pending == nil)
        }

        @Test func `drops when the decision arrived`() {
            let start = radar(session("claude-api", .needsAnswer, pending: question, pendingSince: epoch))
            let next = reduce(start, .stopped(context("claude-api"), time: at(5)))
            #expect(next.sessions[api]?.pendingSince == nil)
        }

        @Test func `records the event time`() {
            let next = reduce(radar(session("claude-api", .working)), .stopped(context("claude-api"), time: at(5)))
            #expect(next.sessions[api]?.updatedAt == at(5))
        }

        @Test func `creates an unseen session as waiting`() {
            let next = reduce(RadarState(), .stopped(context("claude-api"), time: epoch))
            #expect(next.sessions[api]?.state == .waiting)
        }
    }

    struct WhenAWaitingNotificationArrives {
        @Test func `a working session on that surface waits`() {
            let next = reduce(radar(session("claude-api", .working)), .waitingNotification(surfaceID: "surface-1", time: at(5)))
            #expect(next.sessions[api]?.state == .waiting)
        }

        @Test func `records the event time`() {
            let next = reduce(radar(session("claude-api", .working)), .waitingNotification(surfaceID: "surface-1", time: at(5)))
            #expect(next.sessions[api]?.updatedAt == at(5))
        }

        @Test func `a session on another surface is untouched`() {
            let start = radar(session("claude-api", .working, surface: "surface-2"))
            #expect(reduce(start, .waitingNotification(surfaceID: "surface-1", time: at(5))) == start)
        }

        @Test func `an open decision is not overridden`() {
            let start = radar(session("claude-api", .needsPermission, pending: permission, pendingSince: epoch))
            #expect(reduce(start, .waitingNotification(surfaceID: "surface-1", time: at(5))) == start)
        }
    }

    struct WhenTheSessionEnds {
        @Test func `marks it ended`() {
            let next = reduce(radar(session("claude-api", .waiting)), .sessionEnded(api, time: at(5)))
            #expect(next.sessions[api]?.state == .ended)
        }

        @Test func `drops any decision`() {
            let start = radar(session("claude-api", .needsPlanApproval, pending: plan, pendingSince: epoch))
            #expect(reduce(start, .sessionEnded(api, time: at(5))).sessions[api]?.pending == nil)
        }

        @Test func `drops when the decision arrived`() {
            let start = radar(session("claude-api", .needsPlanApproval, pending: plan, pendingSince: epoch))
            #expect(reduce(start, .sessionEnded(api, time: at(5))).sessions[api]?.pendingSince == nil)
        }

        @Test func `records the event time`() {
            let next = reduce(radar(session("claude-api", .waiting)), .sessionEnded(api, time: at(5)))
            #expect(next.sessions[api]?.updatedAt == at(5))
        }

        @Test func `ignores an unseen session`() {
            #expect(reduce(RadarState(), .sessionEnded(api, time: epoch)).sessions.isEmpty)
        }
    }
}
