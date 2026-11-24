public import SwiftUI

/// A command or tool input in monospace on an inset background. Wraps to at most three lines.
public struct CommandBlock: View {
    let text: String

    @Environment(\.radarTheme) private var theme

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(theme.type.mono)
            .foregroundStyle(theme.color(\.textPrimary))
            .lineLimit(3)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, theme.metrics.space12)
            .padding(.vertical, theme.metrics.insetPaddingVertical)
            .background(RoundedRectangle(cornerRadius: theme.metrics.radiusControl).fill(theme.color(\.surfaceInset)))
            .textSelection(.enabled)
    }
}
