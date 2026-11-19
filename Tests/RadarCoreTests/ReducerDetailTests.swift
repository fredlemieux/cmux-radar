// MUTATION-VERIFIED: see ReducerTests.swift (same subject, Reducer.swift; counted once there)
import Foundation
@testable import RadarCore
import Testing

private let api = SessionID("claude-api")

/// Events that change what a session shows, and the passing of time.
enum ReducerDetailTests {
    struct WhenTheTitleChanges {
        @Test func `uses the cmux tab title`() {
            let next = reduce(radar(session("claude-api", .waiting)), .titleChanged(api, title: "API tab"))
            #expect(next.sessions[api]?.title == "API tab")
        }

        @Test func `ignores an unseen session`() {
            #expect(reduce(RadarState(), .titleChanged(api, title: "API tab")).sessions.isEmpty)
        }
    }

    struct WhenTextIsResolved {
        @Test func `stores the last user message`() {
            let next = reduce(radar(session("claude-api", .waiting)), .textResolved(api, lastUserMessage: "ship it", lastAgentMessage: nil))
            #expect(next.sessions[api]?.lastUserMessage == "ship it")
        }

        @Test func `stores the last agent message`() {
            let next = reduce(radar(session("claude-api", .waiting)), .textResolved(api, lastUserMessage: nil, lastAgentMessage: "Done."))
            #expect(next.sessions[api]?.lastAgentMessage == "Done.")
        }

        @Test func `keeps text the resolver did not return`() {
            var known = session("claude-api", .waiting)
            known.lastAgentMessage = "Earlier"
            let next = reduce(radar(known), .textResolved(api, lastUserMessage: "ship it", lastAgentMessage: nil))
            #expect(next.sessions[api]?.lastAgentMessage == "Earlier")
        }

        @Test func `ignores an unseen session`() {
            let next = reduce(RadarState(), .textResolved(api, lastUserMessage: "a", lastAgentMessage: "b"))
            #expect(next.sessions.isEmpty)
        }
    }

    struct WhenTimePasses {
        let policy = Policy.standard

        @Test func `a long-waiting session goes idle`() {
            let next = reduce(radar(session("claude-api", .waiting)), .tick(at(policy.idleAfter + 1)))
            #expect(next.sessions[api]?.state == .idle)
        }

        @Test func `a session waiting exactly the idle time still waits`() {
            let next = reduce(radar(session("claude-api", .waiting)), .tick(at(policy.idleAfter)))
            #expect(next.sessions[api]?.state == .waiting)
        }

        @Test func `going idle keeps the last activity time`() {
            let next = reduce(radar(session("claude-api", .waiting)), .tick(at(policy.idleAfter + 1)))
            #expect(next.sessions[api]?.updatedAt == epoch)
        }

        @Test func `a long-working session keeps working`() {
            let next = reduce(radar(session("claude-api", .working)), .tick(at(policy.idleAfter + 1)))
            #expect(next.sessions[api]?.state == .working)
        }

        @Test func `a long-ended session is dropped`() {
            let next = reduce(radar(session("claude-api", .ended)), .tick(at(policy.hideEndedAfter + 1)))
            #expect(next.sessions[api] == nil)
        }

        @Test func `a session ended exactly the hide time is kept`() {
            let next = reduce(radar(session("claude-api", .ended)), .tick(at(policy.hideEndedAfter)))
            #expect(next.sessions[api] != nil)
        }

        @Test func `a long-idle session is kept`() {
            let next = reduce(radar(session("claude-api", .idle)), .tick(at(policy.hideEndedAfter + 1)))
            #expect(next.sessions[api] != nil)
        }

        @Test func `uses the given policy`() {
            let quick = Policy(idleAfter: 10, hideEndedAfter: 10, pendingTimeout: 10, replyMargin: 0)
            let next = reduce(radar(session("claude-api", .waiting)), .tick(at(11)), policy: quick)
            #expect(next.sessions[api]?.state == .idle)
        }
    }

    struct WhenAWaitingNotificationArrives {
        @Test func `a working session on that surface waits`() {
            let next = reduce(radar(session("claude-api", .working)), .waitingNotification(surfaceID: "surface-1", stamp: stamp(5)))
            #expect(next.sessions[api]?.state == .waiting)
        }

        @Test func `records the event time`() {
            let next = reduce(radar(session("claude-api", .working)), .waitingNotification(surfaceID: "surface-1", stamp: stamp(5)))
            #expect(next.sessions[api]?.updatedAt == at(5))
        }

        @Test func `a session on another surface is untouched`() {
            let start = radar(session("claude-api", .working, surface: "surface-2"))
            #expect(reduce(start, .waitingNotification(surfaceID: "surface-1", stamp: stamp(5))) == start)
        }

        @Test func `a replayed notification does not undo a newer turn`() {
            let start = radar(session("claude-api", .working, updatedAt: at(60)))
            #expect(reduce(start, .waitingNotification(surfaceID: "surface-1", stamp: stamp(5))) == start)
        }

        @Test func `an open decision is not overridden`() {
            let start = radar(session("claude-api", .needsPermission, pending: permission, pendingSince: epoch))
            #expect(reduce(start, .waitingNotification(surfaceID: "surface-1", stamp: stamp(5))) == start)
        }
    }

    struct WhenTheSessionEnds {
        @Test func `marks it ended`() {
            let next = reduce(radar(session("claude-api", .waiting)), .sessionEnded(api, stamp: stamp(5)))
            #expect(next.sessions[api]?.state == .ended)
        }

        @Test func `drops any decision`() {
            let start = radar(session("claude-api", .needsPlanApproval, pending: plan, pendingSince: epoch))
            #expect(reduce(start, .sessionEnded(api, stamp: stamp(5))).sessions[api]?.pending == nil)
        }

        @Test func `drops when the decision arrived`() {
            let start = radar(session("claude-api", .needsPlanApproval, pending: plan, pendingSince: epoch))
            #expect(reduce(start, .sessionEnded(api, stamp: stamp(5))).sessions[api]?.pendingSince == nil)
        }

        @Test func `records the event time`() {
            let next = reduce(radar(session("claude-api", .waiting)), .sessionEnded(api, stamp: stamp(5)))
            #expect(next.sessions[api]?.updatedAt == at(5))
        }

        @Test func `ignores an unseen session`() {
            #expect(reduce(RadarState(), .sessionEnded(api, stamp: stamp(0))).sessions.isEmpty)
        }

        @Test func `ignores an end older than the last activity`() {
            let start = radar(session("claude-api", .working, updatedAt: at(60)))
            #expect(reduce(start, .sessionEnded(api, stamp: stamp(5))) == start)
        }
    }
}
