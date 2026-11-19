public import SwiftUI

/// Status dot, session name, optional location and age on one line.
public struct SessionHeader: View {
    let name: String
    let location: String?
    let age: String
    let status: SessionStatus
    let badge: String?

    @Environment(\.radarTheme) private var theme

    public init(name: String, location: String? = nil, age: String, status: SessionStatus, badge: String? = nil) {
        self.name = name
        self.location = location
        self.age = age
        self.status = status
        self.badge = badge
    }

    public var body: some View {
        HStack(spacing: theme.metrics.space8) {
            StatusDot(status, pulsing: status.needsAttention)
                .frame(width: theme.metrics.dot, height: theme.metrics.dot)
            Text(name)
                .font(theme.type.sessionName)
                .foregroundStyle(theme.color(\.textPrimary))
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(1)
            if let badge {
                Text(badge)
                    .font(theme.type.caption.weight(.medium))
                    .foregroundStyle(theme.status(status))
            }
            if let location {
                Text(location)
                    .font(theme.type.caption.monospaced())
                    .foregroundStyle(theme.color(\.textTertiary))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: theme.metrics.space8)
            Text(age)
                .font(theme.type.caption.monospacedDigit())
                .foregroundStyle(theme.color(\.textTertiary))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(status.accessibilityName), \(age)")
    }
}
