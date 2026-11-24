// MUTATION-VERIFIED: n/a — shared fixtures
import Foundation
import RadarCore

/// Hand-written frames shaped like cmux 0.64.22's `cmux events` output. Ids and paths are made up.
let sessionID = "claude-11111111-2222-3333-4444-555555555555"
let workspaceID = "AAAAAAAA-0000-0000-0000-000000000001"
let surfaceID = "BBBBBBBB-0000-0000-0000-000000000002"
let frameSurfaceID = "CCCCCCCC-0000-0000-0000-000000000003"
let cwd = "/Users/dev/code/api"
let permissionRequestID = "\(sessionID)-PermissionRequest-Bash-1764000000000"

/// 2026-11-24T10:00:00.250Z, the time every fixture frame occurred at.
let occurred = Date(timeIntervalSince1970: 1_795_514_400.25)

/// A JSON value written as a Swift literal; `nil` becomes JSON `null`.
func json(_ object: [String: Any?]) -> String {
    let data = (try? JSONSerialization.data(withJSONObject: cleaned(object), options: [.sortedKeys])) ?? Data()
    return String(bytes: data, encoding: .utf8) ?? ""
}

/// Swaps `nil` for `NSNull`, at every depth, so `JSONSerialization` accepts the literal.
private func cleaned(_ object: [String: Any?]) -> [String: Any] {
    object.mapValues { value in
        if let nested = value as? [String: Any?] {
            return cleaned(nested)
        }
        return value ?? NSNull()
    }
}

func hookPayload(
    _ hook: String,
    phase: String,
    surface: String? = surfaceID,
    tool: String? = nil,
    requestID: String? = nil,
) -> [String: Any?] {
    [
        "session_id": sessionID,
        "cwd": cwd,
        "workspace_id": workspaceID,
        "surface_id": surface,
        "phase": phase,
        "hook_event_name": hook,
        "tool_name": tool,
        "_opencode_request_id": requestID ?? "\(sessionID)-\(hook)-1764000000000",
        "redacted_fields": ["context"],
        "_source": "claude",
    ]
}

func eventFrame(
    _ name: String,
    seq: UInt64 = 42,
    occurredAt: String = "2026-11-24T10:00:00.250Z",
    surface: String? = frameSurfaceID,
    payload: [String: Any?],
) -> String {
    json([
        "type": "event",
        "protocol": "cmux.events",
        "version": 1,
        "seq": seq,
        "name": name,
        "category": name.split(separator: ".").first.map(String.init),
        "occurred_at": occurredAt,
        "workspace_id": workspaceID,
        "surface_id": surface,
        "pane_id": nil,
        "payload": payload,
    ])
}

func hookFrame(_ hook: String, phase: String, surface: String? = surfaceID, tool: String? = nil, requestID: String? = nil) -> String {
    eventFrame("agent.hook.\(hook)", payload: hookPayload(hook, phase: phase, surface: surface, tool: tool, requestID: requestID))
}

func ackFrame(gap: Bool, nextSeq: UInt64?) -> String {
    json([
        "type": "ack",
        "subscription_id": "sub-1",
        "resume": ["after_seq": 10, "gap": gap, "latest_seq": 99, "next_seq": nextSeq, "oldest_seq": 5] as [String: Any?],
    ])
}

let fixtureStamp = Stamp(seq: 42, time: occurred)

let fixtureContext = SessionContext(id: SessionID(sessionID), cwd: cwd, workspaceID: workspaceID, surfaceID: surfaceID)
