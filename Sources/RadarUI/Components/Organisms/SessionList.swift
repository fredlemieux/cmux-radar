public import SwiftUI

/// Every session, most urgent first; a friendly empty state when there are none.
public struct SessionList: View {
    let sessions: [SessionCardModel]
    let actions: SessionActions

    @Environment(\.radarTheme) private var theme

    public init(_ sessions: [SessionCardModel], actions: SessionActions) {
        self.sessions = sessions
        self.actions = actions
    }

    public var body: some View {
        if sessions.isEmpty {
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
        } else {
            ScrollView {
                VStack(spacing: theme.metrics.space8) {
                    ForEach(sortedByUrgency(sessions)) { session in
                        SessionCard(session, actions: actions)
                    }
                }
                .padding(.horizontal, theme.metrics.space10)
                .padding(.bottom, theme.metrics.space10)
            }
            .scrollIndicators(.never)
        }
    }
}
