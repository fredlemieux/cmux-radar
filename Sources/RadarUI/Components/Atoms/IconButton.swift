public import SwiftUI

/// A square button showing an SF Symbol. `filled` uses the waiting accent (the send button).
public struct IconButton: View {
    public enum Style: Sendable {
        case plain
        case filled
    }

    let symbol: String
    let label: String
    let style: Style
    let action: () -> Void

    @Environment(\.radarTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init(_ symbol: String, label: String, style: Style = .plain, action: @escaping () -> Void) {
        self.symbol = symbol
        self.label = label
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: style == .filled ? .bold : .regular))
                .foregroundStyle(foreground)
                .frame(width: theme.metrics.control, height: theme.metrics.control)
                .background(RoundedRectangle(cornerRadius: theme.metrics.radiusControl - 1).fill(background))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .help(label)
    }

    private var foreground: Color {
        switch style {
        case .plain: theme.color(\.textTertiary)
        case .filled: theme.color(\.onStatusWaiting)
        }
    }

    private var background: Color {
        switch style {
        case .plain: .clear
        case .filled: theme.status(isEnabled ? .waiting : .idle)
        }
    }
}
