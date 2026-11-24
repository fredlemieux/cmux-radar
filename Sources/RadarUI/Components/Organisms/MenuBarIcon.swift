public import SwiftUI

/// The menu bar item: a radar glyph, plus a count when sessions need you.
/// Permission requests win over plain waiting (coral beats amber).
public struct MenuBarIcon: View {
    let summary: StatusSummary

    @Environment(\.radarTheme) private var theme

    public init(_ summary: StatusSummary) {
        self.summary = summary
    }

    public var body: some View {
        HStack(spacing: theme.metrics.menuBarSpacing) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(theme.type.menuBarGlyph)
                .foregroundStyle(glyphColor)
            if summary.needingYou > 0 {
                CountBadge(summary.needingYou, attention: summary.permission > 0 ? .permission : .waiting)
            }
        }
        .padding(.horizontal, theme.metrics.menuBarPadding)
        .frame(height: theme.metrics.menuBarHeight)
        .accessibilityElement()
        .accessibilityLabel("cmux radar")
        .accessibilityValue(summaryLine(summary))
    }

    private var glyphColor: Color {
        if summary.working > 0, summary.needingYou == 0 {
            return theme.status(.working)
        }
        return summary.needingYou > 0 ? theme.color(\.textPrimary) : theme.color(\.textTertiary)
    }
}
