public import SwiftUI

/// A keyboard shortcut shown inline, e.g. "⌘1" or "⌥⏎".
public struct KeyHint: View {
    let keys: String

    @Environment(\.radarTheme) private var theme

    public init(_ keys: String) {
        self.keys = keys
    }

    public var body: some View {
        Text(keys)
            .font(theme.type.caption.monospaced())
            .foregroundStyle(theme.color(\.textTertiary))
            .accessibilityLabel("Shortcut \(keys)")
    }
}
