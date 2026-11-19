internal import SwiftUI

public nonisolated extension Palette {
    /// The Radar skin: a phosphor scope. One look in both appearances, so every token is the same
    /// in dark and light. Contrast is tested like Classic's (ThemeContrastTests).
    static let radar = Palette(
        surfaceBase: .both(RGBA(hex: 0x020403)),
        surfacePopover: .both(RGBA(hex: 0x030806)),
        surfaceCard: .both(RGBA(hex: 0x6CFF9E, alpha: 0.05)),
        surfaceCardQuiet: .both(RGBA(hex: 0x6CFF9E, alpha: 0.025)),
        surfaceInset: .both(RGBA(hex: 0x000000, alpha: 0.40)),
        borderSubtle: .both(RGBA(hex: 0x1F4A2C)),
        borderStrong: .both(RGBA(hex: 0x2C7A47)),
        textPrimary: .both(RGBA(hex: 0x6CFF9E)),
        textSecondary: .both(RGBA(hex: 0x8FD9A8)),
        textTertiary: .both(RGBA(hex: 0x3FA765)),
        statusWaiting: .both(RGBA(hex: 0xFFB000)),
        statusPermission: .both(RGBA(hex: 0xFF5A3C)),
        statusWorking: .both(RGBA(hex: 0x6CFF9E)),
        statusIdle: .both(RGBA(hex: 0x3A8F57)),
        onStatusWaiting: .both(RGBA(hex: 0x1A1203)),
        onStatusPermission: .both(RGBA(hex: 0x1F0A04)),
        actionPrimary: .both(RGBA(hex: 0x6CFF9E)),
        onActionPrimary: .both(RGBA(hex: 0x020403)),
    )
}

public nonisolated extension ColorToken {
    /// The same colour in both appearances.
    static func both(_ value: RGBA) -> ColorToken {
        ColorToken(dark: value, light: value)
    }
}

public nonisolated extension Typography {
    /// Everything monospaced, like a terminal readout.
    static var radar: Typography {
        var type = Typography()
        type.title = .system(size: 17, weight: .bold, design: .monospaced)
        type.sessionName = .system(size: 12, weight: .bold, design: .monospaced)
        type.body = .system(size: 11.5, design: .monospaced)
        type.question = .system(size: 15, weight: .semibold, design: .monospaced)
        type.caption = .system(size: 10.5, design: .monospaced)
        type.chip = .system(size: 11.5, weight: .bold, design: .monospaced)
        type.button = .system(size: 11.5, weight: .bold, design: .monospaced)
        type.buttonPrimary = .system(size: 11.5, weight: .bold, design: .monospaced)
        type.icon = .system(size: 12, design: .monospaced)
        type.mono = .system(size: 11.5, design: .monospaced)
        type.sectionLabel = .system(size: 10.5, weight: .bold, design: .monospaced)
        type.badge = .system(size: 10.5, weight: .bold, design: .monospaced)
        type.input = .system(size: 12, design: .monospaced)
        type.rowName = .system(size: 12, design: .monospaced)
        type.rowSummary = .system(size: 11, design: .monospaced)
        type.subtitle = .system(size: 11, design: .monospaced)
        type.link = .system(size: 11, weight: .bold, design: .monospaced)
        type.emptyIcon = .system(size: 22, design: .monospaced)
        type.menuBarGlyph = .system(size: 12, weight: .bold, design: .monospaced)
        return type
    }
}

public nonisolated extension Metrics {
    /// Square corners and a wider popover for the scope.
    static var radar: Metrics {
        var metrics = Metrics()
        metrics.radiusChip = 2
        metrics.radiusControl = 2
        metrics.radiusIconButton = 2
        metrics.radiusInput = 2
        metrics.radiusCard = 2
        metrics.radiusPopover = 4
        metrics.popoverWidth = 460
        return metrics
    }
}

public nonisolated extension Theme {
    /// The Radar skin.
    static let radar = Theme(palette: .radar, typography: .radar, metrics: .radar)
}
