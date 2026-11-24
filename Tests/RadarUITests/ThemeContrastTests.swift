// MUTATION-VERIFIED: n/a — checks token values, not logic
@testable import RadarUI
import Testing

/// One skin's palette in one appearance: every contrast rule holds for each.
struct SkinAppearance: Sendable, CustomStringConvertible {
    let skin: String
    let palette: Palette
    let appearance: Appearance

    var description: String {
        "\(skin) \(appearance)"
    }

    static let all: [SkinAppearance] = [("classic", Palette.classic), ("radar", Palette.radar)].flatMap { skin in
        Appearance.allCases.map { SkinAppearance(skin: skin.0, palette: skin.1, appearance: $0) }
    }
}

/// Every readable pairing in every skin's palette meets WCAG AA (4.5:1) in both appearances.
/// docs/design/components.md §2, "Contrast rule".
struct ThemeContrastTests {
    struct Pairing: Sendable, CustomStringConvertible {
        let name: String
        let foreground: @Sendable (Palette) -> ColorToken
        let background: @Sendable (Palette) -> ColorToken

        var description: String {
            name
        }
    }

    static let pairings: [Pairing] = [
        Pairing(name: "primary text on popover", foreground: { $0.textPrimary }, background: { $0.surfacePopover }),
        Pairing(name: "secondary text on popover", foreground: { $0.textSecondary }, background: { $0.surfacePopover }),
        Pairing(name: "tertiary text on popover", foreground: { $0.textTertiary }, background: { $0.surfacePopover }),
        Pairing(name: "tertiary text on card", foreground: { $0.textTertiary }, background: { $0.surfaceCard }),
        Pairing(name: "primary text on inset", foreground: { $0.textPrimary }, background: { $0.surfaceInset }),
        Pairing(name: "waiting label on popover", foreground: { $0.statusWaiting }, background: { $0.surfacePopover }),
        Pairing(name: "permission label on popover", foreground: { $0.statusPermission }, background: { $0.surfacePopover }),
        Pairing(name: "working label on popover", foreground: { $0.statusWorking }, background: { $0.surfacePopover }),
        Pairing(name: "text on waiting fill", foreground: { $0.onStatusWaiting }, background: { $0.statusWaiting }),
        Pairing(name: "text on permission fill", foreground: { $0.onStatusPermission }, background: { $0.statusPermission }),
        Pairing(name: "text on primary action", foreground: { $0.onActionPrimary }, background: { $0.actionPrimary }),
    ]

    @Test(arguments: pairings, SkinAppearance.all)
    func `meets wcag aa`(pairing: Pairing, theme: SkinAppearance) {
        let palette = theme.palette
        let appearance = theme.appearance
        let popover = palette.surfacePopover.value(for: appearance)
        // Translucent layers are composited over the popover, as on screen.
        let background = pairing.background(palette).value(for: appearance).over(popover)
        let foreground = pairing.foreground(palette).value(for: appearance).over(background)
        #expect(contrastRatio(foreground, background) >= 4.5)
    }
}

/// The highlighted reply chip draws its number in secondary text on a waiting tint.
struct HighlightedChipContrastTests {
    @Test(arguments: SkinAppearance.all)
    func `number meets wcag aa on the tinted fill`(theme: SkinAppearance) {
        let palette = theme.palette
        let appearance = theme.appearance
        let popover = palette.surfacePopover.value(for: appearance)
        let waiting = palette.statusWaiting.value(for: appearance)
        let tint = RGBA(red: waiting.red, green: waiting.green, blue: waiting.blue, alpha: Opacity().tint).over(popover)
        let number = palette.textSecondary.value(for: appearance).over(tint)
        #expect(contrastRatio(number, tint) >= 4.5)
    }
}

/// Status dots and fills are graphics: WCAG 1.4.11 asks for 3:1 against every surface they sit on.
struct StatusGraphicContrastTests {
    @Test(arguments: SessionStatus.allCases, SkinAppearance.all)
    func `status colour meets the non-text minimum on the popover`(status: SessionStatus, theme: SkinAppearance) {
        let palette = theme.palette
        let appearance = theme.appearance
        let popover = palette.surfacePopover.value(for: appearance)
        #expect(contrastRatio(palette.status(status).value(for: appearance), popover) >= 3)
    }

    @Test(arguments: SessionStatus.allCases, SkinAppearance.all)
    func `status colour meets the non-text minimum on a card`(status: SessionStatus, theme: SkinAppearance) {
        let palette = theme.palette
        let appearance = theme.appearance
        let card = palette.surfaceCard.value(for: appearance).over(palette.surfacePopover.value(for: appearance))
        #expect(contrastRatio(palette.status(status).value(for: appearance), card) >= 3)
    }
}

/// The reply field's placeholder and hints sit on an inset, inside a card, on the popover.
struct NestedSurfaceContrastTests {
    @Test(arguments: SkinAppearance.all)
    func `hint text meets wcag aa on an inset inside a card`(theme: SkinAppearance) {
        let palette = theme.palette
        let appearance = theme.appearance
        let popover = palette.surfacePopover.value(for: appearance)
        let card = palette.surfaceCard.value(for: appearance).over(popover)
        let inset = palette.surfaceInset.value(for: appearance).over(card)
        let hint = palette.textTertiary.value(for: appearance).over(inset)
        #expect(contrastRatio(hint, inset) >= 4.5)
    }
}
