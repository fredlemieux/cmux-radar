// MUTATION-VERIFIED: pending
import Foundation
import PropertyBased
@testable import RadarCmux
import RadarCore
import Testing

enum FrameEnvelopeTests {
    struct SessionContextFields {
        @Test func `the payload surface wins over the frame surface`() {
            #expect(decodeFrame(hookFrame("PreToolUse", phase: "received")) == .event(.toolStarted(fixtureContext, stamp: fixtureStamp)))
        }

        @Test func `the frame surface fills a null payload surface`() {
            let expected = SessionContext(id: SessionID(sessionID), cwd: cwd, workspaceID: workspaceID, surfaceID: frameSurfaceID)
            #expect(decodeFrame(hookFrame("PreToolUse", phase: "received", surface: nil)) == .event(.toolStarted(
                expected,
                stamp: fixtureStamp,
            )))
        }

        @Test func `the frame workspace fills a missing payload workspace`() {
            var payload = hookPayload("PreToolUse", phase: "received")
            payload["workspace_id"] = nil as String?
            #expect(decodeFrame(eventFrame("agent.hook.PreToolUse", payload: payload)) == .event(.toolStarted(
                fixtureContext,
                stamp: fixtureStamp,
            )))
        }

        @Test func `a hook without a session id is ignored`() {
            var payload = hookPayload("PreToolUse", phase: "received")
            payload["session_id"] = nil as String?
            #expect(decodeFrame(eventFrame("agent.hook.PreToolUse", payload: payload)) == .ignored)
        }

        @Test func `a hook without a working directory is ignored`() {
            var payload = hookPayload("PreToolUse", phase: "received")
            payload["cwd"] = nil as String?
            #expect(decodeFrame(eventFrame("agent.hook.PreToolUse", payload: payload)) == .ignored)
        }
    }

    struct Stamps {
        @Test func `whole-second times decode`() {
            let frame = eventFrame(
                "agent.hook.PreToolUse",
                occurredAt: "2026-11-24T10:00:00Z",
                payload: hookPayload("PreToolUse", phase: "received"),
            )
            let expected = Stamp(seq: 42, time: occurred.addingTimeInterval(-0.25))
            #expect(decodeFrame(frame) == .event(.toolStarted(fixtureContext, stamp: expected)))
        }

        @Test func `an unreadable time is ignored`() {
            let frame = eventFrame("agent.hook.PreToolUse", occurredAt: "yesterday", payload: hookPayload("PreToolUse", phase: "received"))
            #expect(decodeFrame(frame) == .ignored)
        }

        @Test func `an event without a sequence number is ignored`() {
            var frame = hookPayload("PreToolUse", phase: "received")
            frame = ["type": "event", "name": "agent.hook.PreToolUse", "occurred_at": "2026-11-24T10:00:00Z", "payload": frame]
            #expect(decodeFrame(json(frame)) == .ignored)
        }
    }

    struct Ack {
        @Test func `reports a gap`() {
            #expect(decodeFrame(ackFrame(gap: true, nextSeq: 100)) == .resumed(gap: true, nextSeq: 100))
        }

        @Test func `reports a clean resume`() {
            #expect(decodeFrame(ackFrame(gap: false, nextSeq: 100)) == .resumed(gap: false, nextSeq: 100))
        }

        @Test func `without a next sequence is ignored`() {
            #expect(decodeFrame(ackFrame(gap: true, nextSeq: nil)) == .ignored)
        }

        @Test func `without a gap flag is a clean resume`() {
            #expect(decodeFrame(json(["type": "ack", "resume": ["next_seq": 7] as [String: Any?]])) == .resumed(gap: false, nextSeq: 7))
        }
    }

    struct Malformed {
        @Test func `a heartbeat is ignored`() {
            #expect(decodeFrame(json(["type": "heartbeat", "seq": 3])) == .ignored)
        }

        @Test func `a frame without a type is ignored`() {
            #expect(decodeFrame(json(["seq": 3, "name": "agent.hook.Stop"])) == .ignored)
        }

        @Test func `text that isn't JSON is ignored`() {
            #expect(decodeFrame("not json") == .ignored)
        }

        @Test func `any line decodes without crashing`() async {
            await propertyCheck(input: Gen<Character>.ascii.string(of: 0 ... 200)) { line in
                #expect(decodeFrame(line) == .ignored)
            }
        }
    }
}
