public import SwiftUI

/// A collapsed, quiet session: one line with its last summary.
public struct IdleRow: View {
    let session: SessionCardModel
    let onOpen: () -> Void

    @Environment(\.radarTheme) private var theme

    public init(_ session: SessionCardModel, onOpen: @escaping () -> Void) {
        self.session = session
        self.onOpen = onOpen
    }

    public var body: some View {
        Button(action: onOpen) {
            HStack(spacing: theme.metrics.space8) {
                StatusDot(session.status)
                    .frame(width: theme.metrics.dot, height: theme.metrics.dot)
                Text(session.name)
                    .font(theme.type.rowName)
                    .foregroundStyle(theme.color(\.textSecondary))
                    .lineLimit(1)
                Text(session.summary ?? "")
                    .font(theme.type.rowSummary)
                    .foregroundStyle(theme.color(\.textTertiary))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(session.age)
                    .font(theme.type.caption.monospacedDigit())
                    .foregroundStyle(theme.color(\.textTertiary))
            }
            .padding(.horizontal, theme.metrics.space12)
            .padding(.vertical, theme.metrics.insetPaddingVertical)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(session.name), idle, \(session.age). \(session.summary ?? "")")
        .accessibilityHint("Jumps to the session's tab")
    }
}
