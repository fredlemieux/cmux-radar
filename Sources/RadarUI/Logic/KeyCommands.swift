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
    for reply in session.replies where reply.index == index {
        return reply
    }
    return nil
}

/// What a key press on the list resolves to: which session, and what to do to it.
nonisolated enum RoutedKey: Equatable, Sendable {
    case pick(sessionID: String, ReplyOption)
    case jump(sessionID: String)
}

/// Routes a command to the focused session only, never to another card. `nil` when nothing is
/// focused, the focused session is gone, or it can't take that quick reply now.
nonisolated func route(_ command: KeyCommand, focused: String?, in sessions: [SessionCardModel]) -> RoutedKey? {
    guard let focused, let session = session(focused, in: sessions) else {
        return nil
    }
    switch command {
    case let .pick(index):
        return quickReply(index, in: session).map { .pick(sessionID: session.id, $0) }
    case .jump:
        return .jump(sessionID: session.id)
    }
}

/// The session with that id, if it's still listed.
nonisolated func session(_ id: String, in sessions: [SessionCardModel]) -> SessionCardModel? {
    for session in sessions where session.id == id {
        return session
    }
    return nil
}
