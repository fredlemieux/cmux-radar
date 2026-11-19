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
/// at least two items. Items may carry indented detail lines or nested bullets, and blank lines
/// may sit between them. Anything else gives no suggestions: Radar never makes replies up.
public func suggestedReplies(from message: String?) -> [SuggestedReply] {
    guard let message else {
        return []
    }
    let lines = message.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
    let block = lines.reversed().drop(while: isBlank).prefix(while: belongsToList)
    let items = Array(block.compactMap(listItem).reversed())
    return isOrderedFromOne(items) && items.count >= 2 ? items : []
}

/// A list item, a blank line between items, or an indented detail line under one.
func belongsToList(_ line: String) -> Bool {
    isListItem(line) || isBlank(line) || isIndented(line)
}

func isBlank(_ line: String) -> Bool {
    line.allSatisfy(\.isWhitespace)
}

func isIndented(_ line: String) -> Bool {
    line.first?.isWhitespace ?? false
}

func isListItem(_ line: String) -> Bool {
    listItem(line) != nil
}

/// `"2. Everyone"`, `"2) Everyone"` or `"**2.** Everyone"` → `SuggestedReply(number: 2, label: "Everyone")`.
/// A space must follow the marker, so `1.5 GB` is not an item. Markdown emphasis is dropped.
func listItem(_ line: String) -> SuggestedReply? {
    let start = withoutEmphasisMarker(line.drop(while: \.isWhitespace))
    let digits = start.prefix(while: isASCIIDigit)
    let afterDigits = start.dropFirst(digits.count)
    guard let number = Int(digits), let marker = afterDigits.first, isListMarker(marker) else {
        return nil
    }
    let rest = withoutEmphasisMarker(afterDigits.dropFirst())
    guard rest.first?.isWhitespace ?? false else {
        return nil
    }
    let label = plainText(rest)
    return label.isEmpty ? nil : SuggestedReply(number: number, label: label)
}

func isListMarker(_ character: Character) -> Bool {
    character == "." || character == ")"
}

/// `0`–`9` only: other scripts' digits are not list numbers.
func isASCIIDigit(_ character: Character) -> Bool {
    character.isASCII && character.isNumber
}

/// Drops a leading `**` or `__` (bold around the number).
func withoutEmphasisMarker(_ text: Substring) -> Substring {
    text.hasPrefix("**") || text.hasPrefix("__") ? text.dropFirst(2) : text
}

/// The label without markdown emphasis or code ticks, trimmed.
func plainText(_ text: Substring) -> String {
    let stripped = text.replacing("**", with: "").replacing("__", with: "").replacing("`", with: "")
    return String(stripped.drop(while: \.isWhitespace).reversed().drop(while: \.isWhitespace).reversed())
}

/// Numbered 1, 2, 3… in order.
func isOrderedFromOne(_ items: [SuggestedReply]) -> Bool {
    items.enumerated().allSatisfy { $0.element.number == $0.offset + 1 }
}
