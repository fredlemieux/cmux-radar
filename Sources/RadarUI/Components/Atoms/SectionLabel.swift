public import SwiftUI

/// An uppercase group heading with a count, e.g. "NEEDS YOU · 2", tinted by status.
public struct SectionLabel: View {
    let title: String
    let count: Int
    let status: SessionStatus

    @Environment(\.radarTheme) private var theme

    public init(_ title: String, count: Int, status: SessionStatus) {
        self.title = title
        self.count = count
        self.status = status
    }

    public var body: some View {
        Text(sectionLabelText(title: title, count: count))
            .font(theme.type.sectionLabel)
            .tracking(theme.type.sectionLabelTracking)
            .foregroundStyle(sectionLabelUsesStatusColor(status) ? theme.status(status) : theme.color(\.textTertiary))
            .accessibilityAddTraits(.isHeader)
    }
}
