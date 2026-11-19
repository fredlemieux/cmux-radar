// MUTATION-VERIFIED: killed 10/10 mutants on 2026-11-19 (Reducer.swift, with ReducerTests)
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
            let quick = Policy(idleAfter: 10, hideEndedAfter: 10, pendingTimeout: 10)
            let next = reduce(radar(session("claude-api", .waiting)), .tick(at(11)), policy: quick)
            #expect(next.sessions[api]?.state == .idle)
        }
    }
}
