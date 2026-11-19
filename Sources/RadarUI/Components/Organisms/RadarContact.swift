public import SwiftUI

/// The Radar skin's answer panel for the session calling in: who, its log line, the question or
/// the blocked command, and the same reply controls as Classic, restyled by the theme.
public struct RadarContact: View {
    let session: SessionCardModel?
    let actions: SessionActions

    @Binding private var draft: String
    @Environment(\.radarTheme) private var theme

    public init(_ session: SessionCardModel?, draft: Binding<String>, actions: SessionActions) {
        self.session = session
        _draft = draft
        self.actions = actions
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.space8) {
            if let session {
                header(session)
                if let summary = session.summary {
                    Text("LOG: \(summary)")
                        .font(theme.type.body)
                        .foregroundStyle(theme.color(\.textSecondary))
                        .lineSpacing(theme.type.bodyLineSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                request(session)
            } else {
                Text("NO INBOUND. ALL STATIONS QUIET.")
                    .font(theme.type.caption)
                    .foregroundStyle(theme.color(\.textTertiary))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.metrics.space10)
        .overlay(alignment: .top) {
            Line()
                .stroke(theme.color(\.borderStrong), style: StrokeStyle(lineWidth: theme.metrics.hairline, dash: [4, 3]))
                .frame(height: theme.metrics.hairline)
                .accessibilityHidden(true)
        }
    }

    private func header(_ session: SessionCardModel) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: theme.metrics.space4) {
            Text("INBOUND")
                .foregroundStyle(theme.color(\.textTertiary))
            Text(session.name.uppercased())
                .fontWeight(.bold)
                .foregroundStyle(theme.status(session.status))
            if let location = session.location {
                Text("// \(location)")
                    .foregroundStyle(theme.color(\.textTertiary))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: theme.metrics.space8)
            Text("T+\(session.age)")
                .foregroundStyle(theme.color(\.textTertiary))
        }
        .font(theme.type.caption)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func request(_ session: SessionCardModel) -> some View {
        switch session.status {
        case .waiting:
            if let question = session.question {
                Text(question.uppercased())
                    .font(theme.type.question)
                    .foregroundStyle(theme.status(.waiting))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(question)
            }
            if session.canReply, !session.replies.isEmpty {
                ReplyChips(session.replies) { actions.pick(session.id, $0) }
            }
            ReplyField(
                placeholder: "TRANSMIT TO \(session.name.uppercased())",
                canReply: session.canReply,
                text: $draft,
                onReply: { actions.reply(session.id, $0) },
                onJump: { actions.jump(session.id) },
            )
        case .permission:
            Text("REQUEST: PERMISSION TO RUN")
                .font(theme.type.question)
                .foregroundStyle(theme.status(.permission))
            PermissionBar(
                session.permission ?? PermissionModel(command: "$ (command unavailable)", expired: true),
                onAllow: { actions.allow(session.id) },
                onAlways: { actions.always(session.id) },
                onDeny: { actions.deny(session.id) },
                onJump: { actions.jump(session.id) },
            )
        case .working, .idle:
            EmptyView()
        }
    }
}

/// A horizontal line across its frame, for the dashed divider.
private nonisolated struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}
