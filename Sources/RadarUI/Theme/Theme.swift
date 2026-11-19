public import SwiftUI

/// Type scale. See docs/design/components.md §2.
public struct Typography: Sendable {
    public var title = Font.system(size: 15, weight: .semibold)
    public var sessionName = Font.system(size: 13, weight: .semibold)
    public var body = Font.system(size: 12.5)
    public var question = Font.system(size: 13)
    public var caption = Font.system(size: 11)
    public var chip = Font.system(size: 12, weight: .medium)
    public var mono = Font.system(size: 12, design: .monospaced)
    public var sectionLabel = Font.system(size: 11, weight: .semibold)
    public var badge = Font.system(size: 11, weight: .bold)

    public init() {}
}

/// Space, radius and size scale.
public struct Metrics: Sendable {
    public var space2: CGFloat = 2
    public var space4: CGFloat = 4
    public var space6: CGFloat = 6
    public var space8: CGFloat = 8
    public var space10: CGFloat = 10
    public var space12: CGFloat = 12
    public var space16: CGFloat = 16
    public var radiusChip: CGFloat = 14
    public var radiusControl: CGFloat = 8
    public var radiusInput: CGFloat = 10
    public var radiusCard: CGFloat = 12
    public var radiusPopover: CGFloat = 16
    public var dot: CGFloat = 8
    public var control: CGFloat = 28
    public var controlLarge: CGFloat = 32
    public var replyField: CGFloat = 38
    public var popoverWidth: CGFloat = 436

    public init() {}
}

/// A complete skin: palette plus type and metrics.
public struct Theme: Sendable {
    public var palette: Palette
    public var typography: Typography
    public var metrics: Metrics

    public init(palette: Palette, typography: Typography = Typography(), metrics: Metrics = Metrics()) {
        self.palette = palette
        self.typography = typography
        self.metrics = metrics
    }

    public static let classic = Theme(palette: .classic)

    /// Resolves every colour token for one appearance.
    public func resolved(for appearance: Appearance) -> ResolvedTheme {
        ResolvedTheme(theme: self, appearance: appearance)
    }
}

/// A theme with colours resolved for the current appearance. Components read this.
public struct ResolvedTheme: Sendable {
    public let theme: Theme
    public let appearance: Appearance

    public var type: Typography {
        theme.typography
    }

    public var metrics: Metrics {
        theme.metrics
    }

    public func color(_ token: KeyPath<Palette, ColorToken>) -> Color {
        Color(theme.palette[keyPath: token].value(for: appearance))
    }

    public func status(_ status: SessionStatus) -> Color {
        Color(theme.palette.status(status).value(for: appearance))
    }
}

public extension Color {
    init(_ rgba: RGBA) {
        self.init(.sRGB, red: rgba.red, green: rgba.green, blue: rgba.blue, opacity: rgba.alpha)
    }
}

private struct RadarThemeKey: EnvironmentKey {
    static let defaultValue = Theme.classic.resolved(for: .dark)
}

public extension EnvironmentValues {
    /// The resolved theme. Set it with `.radarTheme(_:)` at the root of a view tree.
    var radarTheme: ResolvedTheme {
        get { self[RadarThemeKey.self] }
        set { self[RadarThemeKey.self] = newValue }
    }
}

public extension View {
    /// Applies `theme`, resolving its colours for the current colour scheme.
    func radarTheme(_ theme: Theme) -> some View {
        modifier(RadarThemeModifier(theme: theme))
    }
}

private struct RadarThemeModifier: ViewModifier {
    let theme: Theme
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.environment(\.radarTheme, theme.resolved(for: colorScheme == .dark ? .dark : .light))
    }
}
