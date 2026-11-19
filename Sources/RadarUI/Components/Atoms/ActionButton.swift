public import SwiftUI

/// A text button for decisions such as Allow once / Always / Deny.
public struct ActionButton: View {
    public enum Style: Sendable {
        /// Solid, high-contrast: the recommended choice.
        case primary
        /// Outlined: the alternatives.
        case outline
    }

    let title: String
    let style: Style
    let action: () -> Void

    @Environment(\.radarTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init(_ title: String, style: Style = .outline, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(style == .primary ? theme.type.buttonPrimary : theme.type.button)
                .foregroundStyle(foreground)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: theme.metrics.controlLarge)
                .background(RoundedRectangle(cornerRadius: theme.metrics.radiusControl).fill(fill))
                .overlay(RoundedRectangle(cornerRadius: theme.metrics.radiusControl).strokeBorder(stroke))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : theme.opacity.disabled)
    }

    private var foreground: Color {
        switch style {
        case .primary: theme.color(\.onActionPrimary)
        case .outline: theme.color(\.textPrimary)
        }
    }

    private var fill: Color {
        switch style {
        case .primary: theme.color(\.actionPrimary)
        case .outline: .clear
        }
    }

    private var stroke: Color {
        switch style {
        case .primary: .clear
        case .outline: theme.color(\.borderStrong)
        }
    }
}
