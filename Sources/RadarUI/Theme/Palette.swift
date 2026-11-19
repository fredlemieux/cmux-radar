/// A colour that has a value for each appearance.
public nonisolated struct ColorToken: Equatable, Sendable {
    public let dark: RGBA
    public let light: RGBA

    public init(dark: RGBA, light: RGBA) {
        self.dark = dark
        self.light = light
    }

    public func value(for appearance: Appearance) -> RGBA {
        switch appearance {
        case .dark: dark
        case .light: light
        }
    }
}

/// Light or dark. Mirrors SwiftUI's `ColorScheme` without importing SwiftUI into pure code.
public nonisolated enum Appearance: CaseIterable, Sendable {
    case dark
    case light
}

/// Every colour the UI uses. See docs/design/components.md §2.
public nonisolated struct Palette: Equatable, Sendable {
    public var surfaceBase: ColorToken
    public var surfacePopover: ColorToken
    public var surfaceCard: ColorToken
    public var surfaceCardQuiet: ColorToken
    public var surfaceInset: ColorToken
    public var borderSubtle: ColorToken
    public var borderStrong: ColorToken
    public var textPrimary: ColorToken
    public var textSecondary: ColorToken
    public var textTertiary: ColorToken
    public var statusWaiting: ColorToken
    public var statusPermission: ColorToken
    public var statusWorking: ColorToken
    public var statusIdle: ColorToken
    public var onStatusWaiting: ColorToken
    public var actionPrimary: ColorToken
    public var onActionPrimary: ColorToken

    public func status(_ status: SessionStatus) -> ColorToken {
        switch status {
        case .waiting: statusWaiting
        case .permission: statusPermission
        case .working: statusWorking
        case .idle: statusIdle
        }
    }
}

public nonisolated extension Palette {
    /// The Classic skin.
    static let classic = Palette(
        surfaceBase: ColorToken(dark: RGBA(hex: 0x0E0F13), light: RGBA(hex: 0xF4F4F6)),
        surfacePopover: ColorToken(dark: RGBA(hex: 0x1C1D23), light: RGBA(hex: 0xFFFFFF)),
        surfaceCard: ColorToken(dark: RGBA(hex: 0xFFFFFF, alpha: 0.05), light: RGBA(hex: 0x000000, alpha: 0.03)),
        surfaceCardQuiet: ColorToken(dark: RGBA(hex: 0xFFFFFF, alpha: 0.03), light: RGBA(hex: 0x000000, alpha: 0.02)),
        surfaceInset: ColorToken(dark: RGBA(hex: 0x000000, alpha: 0.30), light: RGBA(hex: 0x000000, alpha: 0.05)),
        borderSubtle: ColorToken(dark: RGBA(hex: 0xFFFFFF, alpha: 0.09), light: RGBA(hex: 0x000000, alpha: 0.08)),
        borderStrong: ColorToken(dark: RGBA(hex: 0xFFFFFF, alpha: 0.14), light: RGBA(hex: 0x000000, alpha: 0.14)),
        textPrimary: ColorToken(dark: RGBA(hex: 0xF2F2F4), light: RGBA(hex: 0x111114)),
        textSecondary: ColorToken(dark: RGBA(hex: 0xC9C9D1), light: RGBA(hex: 0x3C3C43)),
        textTertiary: ColorToken(dark: RGBA(hex: 0x9A9AA5), light: RGBA(hex: 0x6B6B74)),
        statusWaiting: ColorToken(dark: RGBA(hex: 0xF5A524), light: RGBA(hex: 0x9A6200)),
        statusPermission: ColorToken(dark: RGBA(hex: 0xFF7A59), light: RGBA(hex: 0xC8431F)),
        statusWorking: ColorToken(dark: RGBA(hex: 0x5B9DFF), light: RGBA(hex: 0x2F6FE0)),
        statusIdle: ColorToken(dark: RGBA(hex: 0x6B6B76), light: RGBA(hex: 0xA0A0A8)),
        onStatusWaiting: ColorToken(dark: RGBA(hex: 0x1A1203), light: RGBA(hex: 0xFFFFFF)),
        actionPrimary: ColorToken(dark: RGBA(hex: 0xECECEF), light: RGBA(hex: 0x111114)),
        onActionPrimary: ColorToken(dark: RGBA(hex: 0x111114), light: RGBA(hex: 0xFFFFFF)),
    )
}
