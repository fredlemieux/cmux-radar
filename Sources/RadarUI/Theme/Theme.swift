public import SwiftUI

/// Type scale. See docs/design/components.md §2.
public nonisolated struct Typography: Sendable {
    public var title = Font.system(size: 15, weight: .semibold)
    public var sessionName = Font.system(size: 13, weight: .semibold)
    public var body = Font.system(size: 12.5)
    /// Extra space between body lines (≈ 1.5 line height at 12.5 pt).
    public var bodyLineSpacing: CGFloat = 3
    public var question = Font.system(size: 13)
    public var caption = Font.system(size: 11)
    public var chip = Font.system(size: 12, weight: .medium)
    public var button = Font.system(size: 12.5)
    public var buttonPrimary = Font.system(size: 12.5, weight: .semibold)
    public var icon = Font.system(size: 13)
    public var mono = Font.system(size: 12, design: .monospaced)
    public var sectionLabel = Font.system(size: 11, weight: .semibold)
    /// Section label tracking: +0.06 em at 11 pt.
    public var sectionLabelTracking: CGFloat = 0.66
    public var badge = Font.system(size: 11, weight: .bold)

    public init() {}
}

/// Space, radius and size scale.
public nonisolated struct Metrics: Sendable {
    public var space2: CGFloat = 2
    public var space4: CGFloat = 4
    public var space6: CGFloat = 6
    public var space8: CGFloat = 8
    public var space10: CGFloat = 10
    public var space12: CGFloat = 12
    public var space16: CGFloat = 16
    public var radiusChip: CGFloat = 14
    public var radiusControl: CGFloat = 8
    public var radiusIconButton: CGFloat = 7
    public var radiusInput: CGFloat = 10
    public var radiusCard: CGFloat = 12
    public var radiusPopover: CGFloat = 16
    public var dot: CGFloat = 8
    public var dotRingWidth: CGFloat = 1.5
    public var control: CGFloat = 28
    public var controlLarge: CGFloat = 32
    public var replyField: CGFloat = 38
    public var badgeMin: CGFloat = 16
    public var badgePadding: CGFloat = 5
    public var insetPaddingVertical: CGFloat = 9
    public var progressHeight: CGFloat = 3
    public var chipMaxWidth: CGFloat = 200
    public var popoverWidth: CGFloat = 436

    public init() {}
}

/// Opacities applied to token colours.
public nonisolated struct Opacity: Sendable {
    /// The soft halo behind attention dots.
    public var halo = 0.22
    /// A status-coloured tint behind a highlighted control.
    public var tint = 0.14
    /// Disabled controls.
    public var disabled = 0.45
    /// The border of an attention card.
    public var attentionBorder = 0.38

    public init() {}
}

/// Animation tokens.
public nonisolated struct Motion: Sendable {
    public var pulseDuration = 1.2
    public var pulseScale: CGFloat = 1.25

    public init() {}
}

/// A complete skin: palette plus type, metrics, opacity and motion.
public nonisolated struct Theme: Sendable {
    public var palette: Palette
    public var typography: Typography
    public var metrics: Metrics
    public var opacity: Opacity
    public var motion: Motion

    public init(
        palette: Palette,
        typography: Typography = Typography(),
        metrics: Metrics = Metrics(),
        opacity: Opacity = Opacity(),
        motion: Motion = Motion(),
    ) {
        self.palette = palette
        self.typography = typography
        self.metrics = metrics
        self.opacity = opacity
        self.motion = motion
    }

    public static let classic = Theme(palette: .classic)

    /// Resolves every colour token for one appearance and motion preference.
    public func resolved(for appearance: Appearance, reduceMotion: Bool = false) -> ResolvedTheme {
        ResolvedTheme(theme: self, appearance: appearance, reduceMotion: reduceMotion)
    }
}

/// A theme resolved for the current appearance and motion preference. Components read this.
public nonisolated struct ResolvedTheme: Sendable {
    public let theme: Theme
    public let appearance: Appearance
    /// True when the user has Reduce Motion on (or a story forces it).
    public let reduceMotion: Bool

    public var type: Typography {
        theme.typography
    }

    public var metrics: Metrics {
        theme.metrics
    }

    public var opacity: Opacity {
        theme.opacity
    }

    public var motion: Motion {
        theme.motion
    }

    public func color(_ token: KeyPath<Palette, ColorToken>) -> Color {
        Color(rgba: theme.palette[keyPath: token].value(for: appearance))
    }

    public func status(_ status: SessionStatus) -> Color {
        Color(rgba: theme.palette.status(status).value(for: appearance))
    }
}

nonisolated extension Color {
    init(rgba: RGBA) {
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

/// Whether animations follow the system's Reduce Motion setting or are forced either way.
public nonisolated enum MotionPreference: Sendable {
    case system
    case reduced
    case full
}

public extension View {
    /// Applies `theme` for the current colour scheme. Motion follows the system's Reduce Motion
    /// setting unless `motion` forces it (stories use this to show the reduced state).
    func radarTheme(_ theme: Theme, motion: MotionPreference = .system) -> some View {
        modifier(RadarThemeModifier(theme: theme, motion: motion))
    }
}

private struct RadarThemeModifier: ViewModifier {
    let theme: Theme
    let motion: MotionPreference
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    private var reduces: Bool {
        switch motion {
        case .system: systemReduceMotion
        case .reduced: true
        case .full: false
        }
    }

    func body(content: Content) -> some View {
        content.environment(
            \.radarTheme,
            theme.resolved(for: colorScheme == .dark ? .dark : .light, reduceMotion: reduces),
        )
    }
}
