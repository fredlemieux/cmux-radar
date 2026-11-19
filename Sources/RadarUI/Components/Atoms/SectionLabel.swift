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
            .tracking(0.66)
            .foregroundStyle(status == .idle ? theme.color(\.textTertiary) : theme.status(status))
            .accessibilityAddTraits(.isHeader)
    }
}
