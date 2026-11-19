public import SwiftUI

/// Free-text reply. ⏎ sends (trimmed, never empty) and clears. When the session can't take
/// typed input, it becomes a "Jump to tab" button so there's always an action.
public struct ReplyField: View {
    let placeholder: String
    let canReply: Bool
    let onReply: (String) -> Void
    let onJump: () -> Void

    @State private var text: String
    @Environment(\.radarTheme) private var theme
    @FocusState private var focused: Bool

    public init(
        placeholder: String,
        canReply: Bool = true,
        initialText: String = "",
        onReply: @escaping (String) -> Void,
        onJump: @escaping () -> Void,
    ) {
        self.placeholder = placeholder
        self.canReply = canReply
        self.onReply = onReply
        self.onJump = onJump
        _text = State(initialValue: initialText)
    }

    public var body: some View {
        if canReply {
            field
        } else {
            ActionButton("Jump to tab ⌥⏎", action: onJump)
                .accessibilityHint("This session can't take a typed reply here")
        }
    }

    private var field: some View {
        HStack(spacing: theme.metrics.space8) {
            TextField(text: $text, prompt: Text(placeholder).foregroundStyle(theme.color(\.textTertiary))) {
                Text(placeholder)
            }
            .textFieldStyle(.plain)
            .font(theme.type.input)
            .foregroundStyle(theme.color(\.textPrimary))
            .focused($focused)
            .onSubmit(submit)
            KeyHint("⌥⏎ jump")
            IconButton("arrow.right", label: "Send reply", style: .filled, action: submit)
                .disabled(normalisedReply(text) == nil)
        }
        .padding(.leading, theme.metrics.space12)
        .padding(.trailing, theme.metrics.space6 - 1)
        .frame(height: theme.metrics.replyField)
        .background(RoundedRectangle(cornerRadius: theme.metrics.radiusInput).fill(theme.color(\.surfaceInset)))
        .overlay(
            RoundedRectangle(cornerRadius: theme.metrics.radiusInput)
                .strokeBorder(focused ? theme.status(.waiting) : theme.color(\.borderStrong)),
        )
    }

    private func submit() {
        guard let reply = normalisedReply(text) else {
            return
        }
        onReply(reply)
        text = ""
    }
}
