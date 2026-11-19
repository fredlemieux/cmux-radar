// MUTATION-VERIFIED: see ReducerTests.swift (same subject, Reducer.swift; counted once there)
import Foundation
@testable import RadarCore
import Testing

private let api = SessionID("claude-api")

/// Stream order, not clock order, and bootstrap snapshots of Feed.
enum ReducerOrderingTests {
    struct WhenEventsArriveOutOfOrder {
        @Test func `a decision stamped earlier but streamed later still opens`() {
            let start = radar(session("claude-api", .working))
            let tool = reduce(start, .toolStarted(context("claude-api"), stamp: stamp(10.4, seq: 7)))
            let next = reduce(tool, .decisionRequested(context("claude-api"), permission, stamp: stamp(10, seq: 8)))
            #expect(next.sessions[api]?.state == .needsPermission)
        }

        @Test func `a future-dated event does not freeze the session`() {
            let start = radar(session("claude-api", .working))
            let skewed = reduce(start, .toolStarted(context("claude-api"), stamp: stamp(600, seq: 7)))
            let next = reduce(skewed, .stopped(context("claude-api"), stamp: stamp(20, seq: 8)))
            #expect(next.sessions[api]?.state == .waiting)
        }

        @Test func `an event earlier in the stream is ignored even when stamped later`() {
            let start = radar(session("claude-api", .working, updatedAt: at(60)))
            #expect(reduce(start, .stopped(context("claude-api"), stamp: stamp(90, seq: 10))) == start)
        }
    }

    struct WhenASnapshotSharesThePosition {
        @Test func `a waiting notification at the same position does not undo the turn`() {
            let start = radar(session("claude-api", .working, updatedAt: at(60)))
            #expect(reduce(start, .waitingNotification(surfaceID: "surface-1", stamp: stamp(60))) == start)
        }

        @Test func `a feed list from before the decision does not close it`() {
            let open = radar(session("claude-api", .needsPermission, pending: permission, pendingSince: epoch, updatedAt: at(60)))
            #expect(reduce(open, .decisionsListed(requestIDs: [], stamp: stamp(50))) == open)
        }
    }

    struct WhenAnEndedSessionResumesInAnotherTab {
        let ended = radar(session("claude-api", .ended))

        @Test func `takes the surface it resumed in`() {
            let next = reduce(ended, .promptSubmitted(context("claude-api", surface: "surface-7"), stamp: stamp(5)))
            #expect(next.sessions[api]?.surfaceID == "surface-7")
        }

        @Test func `takes the workspace it resumed in`() {
            let moved = SessionContext(id: api, cwd: "/Users/dev/code/api", workspaceID: "workspace-9", surfaceID: "surface-7")
            #expect(reduce(ended, .promptSubmitted(moved, stamp: stamp(5))).sessions[api]?.workspaceID == "workspace-9")
        }

        @Test func `a live session keeps its workspace`() {
            let moved = SessionContext(id: api, cwd: "/Users/dev/code/api", workspaceID: "workspace-9", surfaceID: "surface-1")
            let live = radar(session("claude-api", .waiting))
            #expect(reduce(live, .promptSubmitted(moved, stamp: stamp(5))).sessions[api]?.workspaceID == "workspace-1")
        }

        @Test func `drops the old surface when the resume has none`() {
            let next = reduce(ended, .promptSubmitted(context("claude-api", surface: nil), stamp: stamp(5)))
            #expect(next.sessions[api]?.surfaceID == nil)
        }
    }

    struct WhenFeedIsListed {
        let open = radar(session("claude-api", .needsPermission, pending: permission, pendingSince: epoch))

        @Test func `closes a decision feed no longer holds`() {
            #expect(reduce(open, .decisionsListed(requestIDs: [], stamp: stamp(5))).sessions[api]?.state == .working)
        }

        @Test func `drops the closed decision`() {
            #expect(reduce(open, .decisionsListed(requestIDs: [], stamp: stamp(5))).sessions[api]?.pending == nil)
        }

        @Test func `keeps a decision feed still holds`() {
            #expect(reduce(open, .decisionsListed(requestIDs: ["req-1"], stamp: stamp(5))) == open)
        }

        @Test func `leaves sessions without a decision alone`() {
            let start = radar(session("claude-api", .waiting))
            #expect(reduce(start, .decisionsListed(requestIDs: [], stamp: stamp(5))) == start)
        }
    }

    struct WhenTheAgentStops {
        @Test func `waits for the user`() {
            let next = reduce(radar(session("claude-api", .working)), .stopped(context("claude-api"), stamp: stamp(5)))
            #expect(next.sessions[api]?.state == .waiting)
        }

        @Test func `drops any decision`() {
            let start = radar(session("claude-api", .needsAnswer, pending: question, pendingSince: epoch))
            let next = reduce(start, .stopped(context("claude-api"), stamp: stamp(5)))
            #expect(next.sessions[api]?.pending == nil)
        }

        @Test func `drops when the decision arrived`() {
            let start = radar(session("claude-api", .needsAnswer, pending: question, pendingSince: epoch))
            let next = reduce(start, .stopped(context("claude-api"), stamp: stamp(5)))
            #expect(next.sessions[api]?.pendingSince == nil)
        }

        @Test func `records the event time`() {
            let next = reduce(radar(session("claude-api", .working)), .stopped(context("claude-api"), stamp: stamp(5)))
            #expect(next.sessions[api]?.updatedAt == at(5))
        }

        @Test func `ignores an unseen session, so a late stop makes no ghost card`() {
            #expect(reduce(RadarState(), .stopped(context("claude-api"), stamp: stamp(0))).sessions.isEmpty)
        }

        @Test func `leaves an ended session ended`() {
            let start = radar(session("claude-api", .ended))
            #expect(reduce(start, .stopped(context("claude-api"), stamp: stamp(5))) == start)
        }
    }
}
