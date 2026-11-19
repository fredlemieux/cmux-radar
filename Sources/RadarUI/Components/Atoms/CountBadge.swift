public import SwiftUI

/// A small rounded count, e.g. the number of sessions waiting. Counts above 99 show "99+".
/// Only attention colours exist, because only they have a tested on-colour for the number.
public struct CountBadge: View {
    let count: Int
    let attention: Attention

    @Environment(\.radarTheme) private var theme

    public init(_ count: Int, attention: Attention = .waiting) {
        self.count = count
        self.attention = attention
    }

    public var body: some View {
        Text(badgeText(for: count))
            .font(theme.type.badge)
            .monospacedDigit()
            .foregroundStyle(theme.color(attention == .permission ? \.onStatusPermission : \.onStatusWaiting))
            .padding(.horizontal, theme.metrics.badgePadding)
            .frame(minWidth: theme.metrics.badgeMin, minHeight: theme.metrics.badgeMin)
            .background(Capsule().fill(theme.status(attention.status)))
            .accessibilityLabel("\(count) \(attention.status.accessibilityName)")
    }
}
