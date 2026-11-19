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
/// at least two items. Items may carry indented detail lines, nested bullets or numbered
/// sublists, and blank lines may sit between them. Anything else gives no suggestions: Radar
/// never makes replies up.
public func suggestedReplies(from message: String?) -> [SuggestedReply] {
    guard let message else {
        return []
    }
    let lines = message.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
    let items = closingList(Array(lines.reversed().drop(while: isBlank)))
    return isOrderedFromOne(items) && items.count >= 2 ? items : []
}

/// Walks up from the last line, collecting the top-level items of the closing list.
///
/// Top level is the indent of the last item; deeper lines (detail, nested bullets, a numbered
/// sublist) and blank lines are skipped. It stops at item 1, at an item out of sequence (an
/// earlier list), or at unindented prose.
func closingList(_ bottomUp: [String]) -> [SuggestedReply] {
    var items: [SuggestedReply] = []
    var level: Int?
    for line in bottomUp where !isBlank(line) {
        let indent = indentation(line)
        guard let item = listItem(line), isTopLevel(indent, level) else {
            guard isDetail(indent, under: level) else {
                break
            }
            continue
        }
        guard continuesUpwards(item, before: items.first) else {
            break
        }
        level = indent
        items.insert(item, at: 0)
        if item.number == 1 {
            break
        }
    }
    return items
}

/// An item at the list's own indent (or the first item found, which sets it).
func isTopLevel(_ indent: Int, _ level: Int?) -> Bool {
    level == nil || indent == level
}

/// Indented further than the list's items (or indented at all, before any item is found).
func isDetail(_ indent: Int, under level: Int?) -> Bool {
    indent > (level ?? 0)
}

/// Reading upwards, each item is numbered one less than the item below it.
func continuesUpwards(_ item: SuggestedReply, before below: SuggestedReply?) -> Bool {
    guard let below else {
        return true
    }
    return item.number == below.number - 1
}

/// Leading whitespace characters.
func indentation(_ line: String) -> Int {
    line.prefix(while: \.isWhitespace).count
}

func isBlank(_ line: String) -> Bool {
    line.allSatisfy(\.isWhitespace)
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

/// The label, trimmed, without emphasis or code ticks that wrap the whole of it. Markers inside
/// it (`__init__`) are kept.
func plainText(_ text: Substring) -> String {
    var label = trimmed(text)
    for marker in ["**", "__", "`"] where isWrapped(label, in: marker) {
        label = trimmed(label.dropFirst(marker.count).dropLast(marker.count))
    }
    return String(label)
}

/// `**Ship**` is wrapped in `**`; `**` alone is not.
func isWrapped(_ text: Substring, in marker: String) -> Bool {
    text.count > marker.count * 2 && text.hasPrefix(marker) && text.hasSuffix(marker)
}

func trimmed(_ text: Substring) -> Substring {
    let start = text.drop(while: \.isWhitespace)
    return start.dropLast(start.reversed().prefix(while: \.isWhitespace).count)
}

/// Numbered 1, 2, 3… in order.
func isOrderedFromOne(_ items: [SuggestedReply]) -> Bool {
    items.enumerated().allSatisfy { $0.element.number == $0.offset + 1 }
}
