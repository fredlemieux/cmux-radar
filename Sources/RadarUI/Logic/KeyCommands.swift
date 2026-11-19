/// What a key press on a focused session card asks for (docs/design/components.md §6).
nonisolated enum KeyCommand: Equatable, Sendable {
    /// ⌘1–9: answer with quick reply N.
    case pick(Int)
    /// ⌥⏎: jump to the session's cmux tab.
    case jump
}

/// Maps a key press to a command, or `nil` when the key isn't one of ours.
nonisolated func keyCommand(characters: String, isReturn: Bool, command: Bool, option: Bool) -> KeyCommand? {
    if isReturn {
        return option ? .jump : nil
    }
    guard command, let digit = Int(characters), (1 ... 9).contains(digit) else {
        return nil
    }
    return .pick(digit)
}

/// The quick reply a ⌘N press should send, if the session can take one right now.
nonisolated func quickReply(_ index: Int, in session: SessionCardModel) -> ReplyOption? {
    guard session.status == .waiting, session.canReply else {
        return nil
    }
    return session.replies.first { $0.index == index }
}
