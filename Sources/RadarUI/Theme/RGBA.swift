internal import Foundation

/// An sRGB colour with straight (non-premultiplied) alpha, each channel 0…1.
///
/// Pure value type so colour maths (compositing, WCAG contrast) is testable without SwiftUI.
public nonisolated struct RGBA: Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = clampUnit(red)
        self.green = clampUnit(green)
        self.blue = clampUnit(blue)
        self.alpha = clampUnit(alpha)
    }

    /// `0xRRGGBB`, opaque.
    public init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            alpha: alpha,
        )
    }

    public static let white = RGBA(hex: 0xFFFFFF)
    public static let black = RGBA(hex: 0x000000)

    /// This colour drawn over an opaque `background` ("source over").
    public func over(_ background: RGBA) -> RGBA {
        RGBA(
            red: red * alpha + background.red * (1 - alpha),
            green: green * alpha + background.green * (1 - alpha),
            blue: blue * alpha + background.blue * (1 - alpha),
        )
    }

    /// WCAG 2.x relative luminance of the opaque colour, 0 (black) … 1 (white).
    public var relativeLuminance: Double {
        0.2126 * linearize(red) + 0.7152 * linearize(green) + 0.0722 * linearize(blue)
    }
}

/// WCAG 2.x contrast ratio between two opaque colours, 1…21. Order doesn't matter.
nonisolated func contrastRatio(_ first: RGBA, _ second: RGBA) -> Double {
    let lighter = max(first.relativeLuminance, second.relativeLuminance)
    let darker = min(first.relativeLuminance, second.relativeLuminance)
    return (lighter + 0.05) / (darker + 0.05)
}

private nonisolated func linearize(_ channel: Double) -> Double {
    if channel <= 0.039_28 {
        return channel / 12.92
    }
    return pow((channel + 0.055) / 1.055, 2.4)
}

private nonisolated func clampUnit(_ value: Double) -> Double {
    min(max(value, 0), 1)
}
