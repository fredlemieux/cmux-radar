internal import SwiftUI

extension KeyPress {
    /// The command this press asks for, if it's one of ours (⌘1–9, ⌥⏎).
    var sessionCommand: KeyCommand? {
        keyCommand(
            characters: characters,
            isReturn: key == .return,
            command: modifiers.contains(.command),
            option: modifiers.contains(.option),
        )
    }
}

extension SessionActions {
    /// Sends a routed shortcut to its session. Shared by every skin so routing can't drift.
    func perform(_ routed: RoutedKey) {
        switch routed {
        case let .pick(id, option): pick(id, option)
        case let .jump(id): jump(id)
        }
    }
}
