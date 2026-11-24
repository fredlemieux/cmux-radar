// MUTATION-VERIFIED: killed 9/9 mutants on 2026-11-24 (FrameDecoder.swift)
import Foundation
@testable import RadarCmux
import RadarCore
import Testing

enum FrameDecoderTests {
    struct UserPromptSubmit {
        @Test func `received becomes prompt submitted`() {
            #expect(decodeFrame(hookFrame("UserPromptSubmit", phase: "received")) == .event(.promptSubmitted(
                fixtureContext,
                stamp: fixtureStamp,
            )))
        }

        @Test func `completed is ignored`() {
            #expect(decodeFrame(hookFrame("UserPromptSubmit", phase: "completed")) == .ignored)
        }
    }

    struct PreToolUse {
        @Test func `received becomes tool started`() {
            #expect(decodeFrame(hookFrame("PreToolUse", phase: "received")) == .event(.toolStarted(fixtureContext, stamp: fixtureStamp)))
        }

        @Test func `completed is ignored`() {
            #expect(decodeFrame(hookFrame("PreToolUse", phase: "completed")) == .ignored)
        }
    }

    struct Stop {
        @Test func `completed becomes stopped`() {
            #expect(decodeFrame(hookFrame("Stop", phase: "completed")) == .event(.stopped(fixtureContext, stamp: fixtureStamp)))
        }

        @Test func `received is ignored`() {
            #expect(decodeFrame(hookFrame("Stop", phase: "received")) == .ignored)
        }
    }

    struct SessionEnd {
        @Test func `received becomes session ended`() {
            #expect(decodeFrame(hookFrame("SessionEnd", phase: "received")) == .event(.sessionEnded(
                SessionID(sessionID),
                stamp: fixtureStamp,
            )))
        }

        @Test func `completed is ignored`() {
            #expect(decodeFrame(hookFrame("SessionEnd", phase: "completed")) == .ignored)
        }
    }

    struct PermissionRequest {
        @Test func `received asks for the Feed item`() {
            let frame = hookFrame("PermissionRequest", phase: "received", tool: "Bash", requestID: permissionRequestID)
            #expect(decodeFrame(frame) == .decisionPending(
                fixtureContext,
                requestID: permissionRequestID,
                tool: "Bash",
                stamp: fixtureStamp,
            ))
        }

        @Test func `received without a tool name has an empty tool`() {
            let frame = hookFrame("PermissionRequest", phase: "received", requestID: permissionRequestID)
            #expect(decodeFrame(frame) == .decisionPending(fixtureContext, requestID: permissionRequestID, tool: "", stamp: fixtureStamp))
        }

        @Test func `received without a request id is ignored`() {
            var payload = hookPayload("PermissionRequest", phase: "received", tool: "Bash")
            payload["_opencode_request_id"] = nil as String?
            #expect(decodeFrame(eventFrame("agent.hook.PermissionRequest", payload: payload)) == .ignored)
        }

        @Test func `completed on the Feed resolves the request`() {
            let payload = hookPayload("PermissionRequest", phase: "completed", tool: "Bash", requestID: permissionRequestID)
            let expected = CmuxSignal.event(.decisionResolved(requestID: permissionRequestID, stamp: fixtureStamp))
            #expect(decodeFrame(eventFrame("feed.item.completed", payload: payload)) == expected)
        }

        @Test func `completed on the agent hook is ignored`() {
            #expect(decodeFrame(hookFrame("PermissionRequest", phase: "completed", requestID: permissionRequestID)) == .ignored)
        }
    }

    struct FeedItemResolved {
        @Test func `resolves the replied request`() {
            let frame = eventFrame("feed.item.resolved", payload: ["request_id": permissionRequestID, "mode": "once"])
            #expect(decodeFrame(frame) == .event(.decisionResolved(requestID: permissionRequestID, stamp: fixtureStamp)))
        }

        @Test func `without a request id is ignored`() {
            #expect(decodeFrame(eventFrame("feed.item.resolved", payload: ["mode": "once"])) == .ignored)
        }
    }

    struct FeedTelemetry {
        @Test func `a received item duplicates its hook and is ignored`() {
            #expect(decodeFrame(eventFrame("feed.item.received", payload: hookPayload("UserPromptSubmit", phase: "received"))) == .ignored)
        }

        @Test func `a completed item for another hook is ignored`() {
            #expect(decodeFrame(eventFrame("feed.item.completed", payload: hookPayload("Stop", phase: "completed"))) == .ignored)
        }
    }

    struct UnusedHooks {
        @Test func `session start is ignored`() {
            #expect(decodeFrame(hookFrame("SessionStart", phase: "received")) == .ignored)
        }

        @Test func `subagent stop is ignored`() {
            #expect(decodeFrame(hookFrame("SubagentStop", phase: "completed")) == .ignored)
        }

        @Test func `a notification is ignored`() {
            #expect(decodeFrame(eventFrame("notification.created", payload: ["notification_id": "n-1"])) == .ignored)
        }
    }
}
