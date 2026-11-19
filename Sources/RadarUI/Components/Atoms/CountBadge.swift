public import SwiftUI

/// A small rounded count, e.g. the number of sessions waiting. Counts above 99 show "99+".
public struct CountBadge: View {
    let count: Int
    let status: SessionStatus

    @Environment(\.radarTheme) private var theme

    public init(_ count: Int, status: SessionStatus = .waiting) {
        self.count = count
        self.status = status
    }

    public var body: some View {
        Text(badgeText(for: count))
            .font(theme.type.badge)
            .monospacedDigit()
            .foregroundStyle(theme.color(\.onStatusWaiting))
            .padding(.horizontal, 5)
            .frame(minWidth: 16, minHeight: 16)
            .background(Capsule().fill(theme.status(status)))
            .accessibilityLabel("\(count) \(status.accessibilityName)")
    }
}
