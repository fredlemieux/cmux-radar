// MUTATION-VERIFIED: n/a — checks token values, not logic
import RadarUI
import Testing

/// Every readable pairing in the Classic palette meets WCAG AA (4.5:1) in both appearances.
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
        Pairing(name: "text on primary action", foreground: { $0.onActionPrimary }, background: { $0.actionPrimary }),
    ]

    @Test(arguments: pairings, Appearance.allCases)
    func `meets wcag aa`(pairing: Pairing, appearance: Appearance) {
        let palette = Palette.classic
        let popover = palette.surfacePopover.value(for: appearance)
        // Translucent layers are composited over the popover, as on screen.
        let background = pairing.background(palette).value(for: appearance).over(popover)
        let foreground = pairing.foreground(palette).value(for: appearance).over(background)
        #expect(contrastRatio(foreground, background) >= 4.5)
    }
}
