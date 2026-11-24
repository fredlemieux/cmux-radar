internal import Foundation

/// A `feed.list` response.
struct WireFeedList: Decodable {
    let items: [WireFeedItem]
}

/// One Feed item. Only the fields Radar reads; all optional so new kinds still decode.
struct WireFeedItem: Decodable {
    let kind: String?
    let workstreamID: String?
    let cwd: String?
    let requestID: String?
    let toolName: String?
    let toolInput: String?
    let questionPrompt: String?
    let questionOptions: [WireOption]?
    let questions: [WireQuestion]?

    enum CodingKeys: String, CodingKey {
        case kind, cwd, questions
        case workstreamID = "workstream_id"
        case requestID = "request_id"
        case toolName = "tool_name"
        case toolInput = "tool_input"
        case questionPrompt = "question_prompt"
        case questionOptions = "question_options"
    }
}

struct WireQuestion: Decodable {
    let prompt: String?
    let options: [WireOption]?
}

struct WireOption: Decodable {
    let id: String?
    let label: String
}

/// A value in the tool input object. Only strings matter to Radar; anything else is `.other`.
enum WireInputValue: Decodable {
    case text(String)
    case other

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else {
            self = .other
        }
    }
}
