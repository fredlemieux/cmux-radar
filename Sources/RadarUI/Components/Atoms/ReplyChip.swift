public import SwiftUI

/// A one-tap quick reply: its number and a short label, e.g. "1 Build it".
public struct ReplyChip: View {
    let index: Int
    let label: String
    let highlighted: Bool
    let action: () -> Void

    @Environment(\.radarTheme) private var theme

    public init(index: Int, label: String, highlighted: Bool = false, action: @escaping () -> Void) {
        self.index = index
        self.label = label
        self.highlighted = highlighted
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: theme.metrics.space6) {
                Text(String(index))
                    .foregroundStyle(theme.color(\.textTertiary))
                    .monospacedDigit()
                Text(label)
                    .foregroundStyle(theme.color(\.textPrimary))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .font(theme.type.chip)
            .padding(.horizontal, theme.metrics.space10)
            .frame(height: theme.metrics.control)
            .frame(maxWidth: 200)
            .background(Capsule().fill(highlighted ? theme.status(.waiting).opacity(0.14) : theme.color(\.surfaceCard)))
            .overlay(Capsule().strokeBorder(highlighted ? theme.status(.waiting) : theme.color(\.borderStrong)))
            .fixedSize(horizontal: true, vertical: false)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reply \(index): \(label)")
    }
}
