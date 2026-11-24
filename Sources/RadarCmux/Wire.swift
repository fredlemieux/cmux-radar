internal import Foundation

/// One NDJSON frame from `cmux events` / `events.stream`, as cmux writes it. Every field is
/// optional: frames we don't understand decode to `.ignored` instead of failing.
struct WireFrame: Decodable {
    let type: String?
    let seq: UInt64?
    let name: String?
    let occurredAt: String?
    let workspaceID: String?
    let surfaceID: String?
    let payload: WirePayload?
    let resume: WireResume?

    enum CodingKeys: String, CodingKey {
        case type, seq, name, payload, resume
        case occurredAt = "occurred_at"
        case workspaceID = "workspace_id"
        case surfaceID = "surface_id"
    }
}

/// The agent-hook payload. Text fields are redacted by cmux, so only identity and timing remain.
struct WirePayload: Decodable {
    let sessionID: String?
    let cwd: String?
    let workspaceID: String?
    let surfaceID: String?
    let phase: String?
    let hookEventName: String?
    let toolName: String?
    let hookRequestID: String?
    let requestID: String?

    enum CodingKeys: String, CodingKey {
        case cwd, phase
        case sessionID = "session_id"
        case workspaceID = "workspace_id"
        case surfaceID = "surface_id"
        case hookEventName = "hook_event_name"
        case toolName = "tool_name"
        case hookRequestID = "_opencode_request_id"
        case requestID = "request_id"
    }
}

/// The subscription ack's resume block.
struct WireResume: Decodable {
    /// A missing flag means no gap.
    let gap: Bool
    let nextSeq: UInt64?

    enum CodingKeys: String, CodingKey {
        case gap
        case nextSeq = "next_seq"
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gap = try container.decodeIfPresent(Bool.self, forKey: .gap) ?? false
        nextSeq = try container.decodeIfPresent(UInt64.self, forKey: .nextSeq)
    }
}

/// cmux timestamps are ISO 8601, with or without fractional seconds.
func cmuxDate(_ text: String) -> Date? {
    if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(text) {
        return date
    }
    return try? Date.ISO8601FormatStyle().parse(text)
}

/// Decodes `T` from a UTF-8 string, or nil when the text isn't valid JSON of that shape.
func decodeJSON<T: Decodable>(_: T.Type, from text: String) -> T? {
    try? JSONDecoder().decode(T.self, from: Data(text.utf8))
}
