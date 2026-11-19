public import SwiftUI

/// Every session, most urgent first; a friendly empty state when there are none.
///
/// Keyboard (docs/design/components.md §6): ⇥ moves between cards, ⌘1–9 sends that quick reply on
/// the focused card, ⌥⏎ jumps to the focused card's tab. Reply drafts are held by the caller,
/// keyed by session id.
public struct SessionList: View {
    let sessions: [SessionCardModel]
    let actions: SessionActions
    @Binding var drafts: [String: String]

    @Environment(\.radarTheme) private var theme
    @FocusState private var focused: String?

    public init(_ sessions: [SessionCardModel], drafts: Binding<[String: String]>, actions: SessionActions) {
        self.sessions = sessions
        _drafts = drafts
        self.actions = actions
    }

    public var body: some View {
        if sessions.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: theme.metrics.space8) {
                    ForEach(sortedByUrgency(sessions)) { session in
                        SessionCard(session, draft: draft(for: session.id), actions: actions)
                            .focusable()
                            .focused($focused, equals: session.id)
                            .overlay {
                                RoundedRectangle(cornerRadius: theme.metrics.radiusCard)
                                    .strokeBorder(theme.status(.working), lineWidth: 2)
                                    .opacity(focused == session.id ? 1 : 0)
                                    .allowsHitTesting(false)
                            }
                    }
                }
                .padding(.horizontal, theme.metrics.space10)
                .padding(.bottom, theme.metrics.space10)
            }
            .scrollIndicators(.never)
            .onKeyPress(phases: .down, action: handle)
        }
    }

    private var emptyState: some View {
        VStack(spacing: theme.metrics.space6) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(theme.type.emptyIcon)
                .foregroundStyle(theme.color(\.textTertiary))
                .accessibilityHidden(true)
            Text("All quiet")
                .font(theme.type.sessionName)
                .foregroundStyle(theme.color(\.textPrimary))
            Text("No agents are running in cmux.")
                .font(theme.type.caption)
                .foregroundStyle(theme.color(\.textTertiary))
        }
        .frame(maxWidth: .infinity, minHeight: theme.metrics.emptyStateHeight)
    }

    private func draft(for id: String) -> Binding<String> {
        Binding(get: { drafts[id] ?? "" }, set: { drafts[id] = $0 })
    }

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        guard
            let id = focused,
            let session = sessions.first(where: { $0.id == id }),
            let command = keyCommand(
                characters: press.characters,
                isReturn: press.key == .return,
                command: press.modifiers.contains(.command),
                option: press.modifiers.contains(.option),
            )
        else {
            return .ignored
        }
        switch command {
        case let .pick(index):
            guard let option = quickReply(index, in: session) else {
                return .ignored
            }
            actions.pick(id, option)
        case .jump:
            actions.jump(id)
        }
        return .handled
    }
}
