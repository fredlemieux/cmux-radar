/// A reply chip offered from the agent's own numbered list; choosing it sends `number`.
public struct SuggestedReply: Equatable, Sendable {
    public let number: Int
    public let label: String

    public init(number: Int, label: String) {
        self.number = number
        self.label = label
    }
}

/// The numbered list the agent's message ends with, as reply chips (docs/SPEC.md §4).
///
/// Only a list that closes the message counts, numbered `1.` (or `1)`) upwards without gaps, with
/// at least two items. Anything else gives no suggestions: Radar never makes replies up.
public func suggestedReplies(from message: String?) -> [SuggestedReply] {
    guard let message else {
        return []
    }
    let lines = message.split(whereSeparator: \.isNewline).map(String.init)
    let trailing = lines.reversed().drop { $0.allSatisfy(\.isWhitespace) }
    let items = Array(trailing.prefix(while: isListItem).compactMap(listItem).reversed())
    return isOrderedFromOne(items) && items.count >= 2 ? items : []
}

/// `"2. Everyone"` or `"2) Everyone"` → `SuggestedReply(number: 2, label: "Everyone")`.
func listItem(_ line: String) -> SuggestedReply? {
    let trimmed = line.drop { $0.isWhitespace }
    let digits = trimmed.prefix(while: isASCIIDigit)
    let rest = trimmed.dropFirst(digits.count)
    guard let number = Int(digits), let marker = rest.first, marker == "." || marker == ")" else {
        return nil
    }
    let label = rest.dropFirst().trimmingWhitespace()
    return label.isEmpty ? nil : SuggestedReply(number: number, label: label)
}

func isListItem(_ line: String) -> Bool {
    listItem(line) != nil
}

/// `0`–`9` only: other scripts' digits are not list numbers.
func isASCIIDigit(_ character: Character) -> Bool {
    character.isASCII && character.isNumber
}

/// Numbered 1, 2, 3… in order.
func isOrderedFromOne(_ items: [SuggestedReply]) -> Bool {
    items.enumerated().allSatisfy { $0.element.number == $0.offset + 1 }
}

private extension Substring {
    func trimmingWhitespace() -> String {
        String(drop { $0.isWhitespace }.reversed().drop { $0.isWhitespace }.reversed())
    }
}
