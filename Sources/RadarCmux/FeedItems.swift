public import Foundation
public import RadarCore

/// A Feed item the agent is blocked on, decoded from `feed.list`.
public struct FeedDecision: Equatable, Sendable {
    public let sessionID: SessionID
    public let cwd: String
    public let decision: PendingDecision

    public init(sessionID: SessionID, cwd: String, decision: PendingDecision) {
        self.sessionID = sessionID
        self.cwd = cwd
        self.decision = decision
    }
}

/// Decodes a `feed.list` response into the decisions it holds. Telemetry items (prompts, tool
/// use, stops) and items without a request id are skipped; unreadable JSON gives an empty list.
public func decodeFeedList(_ data: Data) -> [FeedDecision] {
    let list = try? JSONDecoder().decode(WireFeedList.self, from: data)
    var decisions: [FeedDecision] = []
    for item in list?.items ?? [] {
        if let decision = feedDecision(item) {
            decisions.append(decision)
        }
    }
    return decisions
}

/// The bootstrap event for a `feed.list { pending_only: true }` read: the request ids Feed still
/// holds. The reducer closes any other open decision.
public func decisionsListed(_ decisions: [FeedDecision], stamp: Stamp) -> RadarEvent {
    var requestIDs = Set<String>()
    for item in decisions {
        requestIDs.insert(item.decision.requestID)
    }
    return .decisionsListed(requestIDs: requestIDs, stamp: stamp)
}

func feedDecision(_ item: WireFeedItem) -> FeedDecision? {
    if let requestID = item.requestID, let sessionID = item.workstreamID, let decision = pendingDecision(item, requestID: requestID) {
        return FeedDecision(sessionID: SessionID(sessionID), cwd: item.cwd ?? "", decision: decision)
    }
    return nil
}

func pendingDecision(_ item: WireFeedItem, requestID: String) -> PendingDecision? {
    switch item.kind {
    case "permissionRequest":
        .permission(requestID: requestID, tool: item.toolName ?? "", input: commandText(item.toolInput))
    case "question":
        .question(requestID: requestID, questions: questions(item))
    case "exitPlan":
        .plan(requestID: requestID, plan: inputField("plan", of: item.toolInput) ?? "")
    default:
        nil
    }
}

/// What a permission request wants to run: the `command` of a shell tool, else the raw input.
func commandText(_ toolInput: String?) -> String {
    inputField("command", of: toolInput) ?? toolInput ?? ""
}

/// A string field of the tool input, which cmux sends as a JSON-encoded string.
func inputField(_ key: String, of toolInput: String?) -> String? {
    if let toolInput, case let .text(value)? = decodeJSON([String: WireInputValue].self, from: toolInput)?[key] {
        return value
    }
    return nil
}

/// The questions asked; older items carry a single `question_prompt` instead of `questions`.
func questions(_ item: WireFeedItem) -> [Question] {
    var result: [Question] = []
    for question in item.questions ?? [] {
        result.append(Question(prompt: question.prompt ?? "", options: options(question.options)))
    }
    if result.isEmpty, let prompt = item.questionPrompt {
        result.append(Question(prompt: prompt, options: options(item.questionOptions)))
    }
    return result
}

func options(_ wire: [WireOption]?) -> [QuestionOption] {
    var result: [QuestionOption] = []
    for option in wire ?? [] {
        result.append(QuestionOption(id: option.id ?? option.label, label: option.label))
    }
    return result
}
