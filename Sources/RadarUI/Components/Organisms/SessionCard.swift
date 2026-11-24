public import SwiftUI

/// What a card can ask the app to do. The app layer wires these to cmux; stories log them.
public struct SessionActions {
    public var reply: (_ sessionID: String, _ text: String) -> Void
    public var pick: (_ sessionID: String, _ option: ReplyOption) -> Void
    public var allow: (_ sessionID: String) -> Void
    public var always: (_ sessionID: String) -> Void
    public var deny: (_ sessionID: String) -> Void
    public var jump: (_ sessionID: String) -> Void

    public init(
        reply: @escaping (String, String) -> Void,
        pick: @escaping (String, ReplyOption) -> Void,
        allow: @escaping (String) -> Void,
        always: @escaping (String) -> Void,
        deny: @escaping (String) -> Void,
        jump: @escaping (String) -> Void,
    ) {
        self.reply = reply
        self.pick = pick
        self.allow = allow
        self.always = always
        self.deny = deny
        self.jump = jump
    }

    /// Does nothing. For previews and snapshots.
    public static let none = SessionActions(
        reply: { _, _ in }, pick: { _, _ in }, allow: { _ in }, always: { _ in }, deny: { _ in }, jump: { _ in },
    )
}

/// One session. The body depends on the status: question + replies, permission, progress or idle.
public struct SessionCard: View {
    let session: SessionCardModel
    let actions: SessionActions
    @Binding var draft: String

    @Environment(\.radarTheme) private var theme

    public init(_ session: SessionCardModel, draft: Binding<String>, actions: SessionActions) {
        self.session = session
        _draft = draft
        self.actions = actions
    }

    public var body: some View {
        switch session.status {
        case .idle:
            IdleRow(session) { actions.jump(session.id) }
        case .waiting, .permission, .working:
            card
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: theme.metrics.space10) {
            SessionHeader(
                name: session.name,
                location: session.location,
                age: session.age,
                status: session.status,
                badge: session.status == .permission ? "Permission" : nil,
            )
            content
        }
        .padding(theme.metrics.space12)
        .background(RoundedRectangle(cornerRadius: theme.metrics.radiusCard).fill(fill))
        .overlay(RoundedRectangle(cornerRadius: theme.metrics.radiusCard).strokeBorder(border))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(session.name), \(session.status.accessibilityName)")
    }

    @ViewBuilder private var content: some View {
        if let summary = session.summary {
            Text(summary)
                .font(theme.type.body)
                .foregroundStyle(theme.color(\.textSecondary))
                .lineSpacing(theme.type.bodyLineSpacing)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        switch session.status {
        case .waiting:
            waitingBody
        case .permission:
            if let permission = session.permission {
                PermissionBar(
                    permission,
                    onAllow: { actions.allow(session.id) },
                    onAlways: { actions.always(session.id) },
                    onDeny: { actions.deny(session.id) },
                    onJump: { actions.jump(session.id) },
                )
            } else {
                // No request details: there's still always something to do.
                ActionButton("Jump to tab", style: .primary) { actions.jump(session.id) }
            }
        case .working:
            if let progress = session.progress {
                ProgressBar(progress)
            }
        case .idle:
            EmptyView()
        }
    }

    @ViewBuilder private var waitingBody: some View {
        if let question = session.question {
            QuestionBlock(question)
        }
        if session.canReply, !session.replies.isEmpty {
            ReplyChips(session.replies) { actions.pick(session.id, $0) }
        }
        ReplyField(
            placeholder: "Reply to \(session.name)…",
            canReply: session.canReply,
            text: $draft,
            onReply: { actions.reply(session.id, $0) },
            onJump: { actions.jump(session.id) },
        )
    }

    private var fill: Color {
        session.status == .working ? theme.color(\.surfaceCardQuiet) : theme.color(\.surfaceCard)
    }

    private var border: Color {
        switch session.status {
        case .waiting, .permission: theme.status(session.status).opacity(theme.opacity.attentionBorder)
        case .working, .idle: .clear
        }
    }
}
