// MUTATION-VERIFIED: killed 1/1 mutants on 2026-11-19 (RGBA.swift; Muter has no arithmetic operators, see docs/standards.md)
import PropertyBased
import RadarUI
import Testing

private let channel = Gen.double(in: 0 ... 1)

enum ContrastRatioTests {
    struct Properties {
        @Test func `stays between one and twenty one`() async {
            await propertyCheck(input: channel, channel, channel, channel, channel, channel) { red1, green1, blue1, red2, green2, blue2 in
                let ratio = contrastRatio(RGBA(red: red1, green: green1, blue: blue1), RGBA(red: red2, green: green2, blue: blue2))
                #expect((1 ... 21.000_001).contains(ratio))
            }
        }

        @Test func `does not depend on argument order`() async {
            await propertyCheck(input: channel, channel, channel, channel, channel, channel) { red1, green1, blue1, red2, green2, blue2 in
                let first = RGBA(red: red1, green: green1, blue: blue1)
                let second = RGBA(red: red2, green: green2, blue: blue2)
                #expect(contrastRatio(first, second) == contrastRatio(second, first))
            }
        }

        @Test func `is one for a colour against itself`() async {
            await propertyCheck(input: channel, channel, channel) { red, green, blue in
                let colour = RGBA(red: red, green: green, blue: blue)
                #expect(contrastRatio(colour, colour) == 1)
            }
        }
    }

    struct Examples {
        @Test func `black on white is twenty one`() {
            #expect(abs(contrastRatio(.black, .white) - 21) < 0.000_001)
        }

        @Test func `mid grey on white matches the wcag reference`() {
            // #777777 on white is 4.48:1 in the WCAG reference implementation.
            #expect(abs(contrastRatio(RGBA(hex: 0x777777), .white) - 4.48) < 0.01)
        }
    }
}

struct RelativeLuminanceTests {
    @Test func `black is zero`() {
        #expect(RGBA.black.relativeLuminance == 0)
    }

    @Test func `white is one`() {
        #expect(abs(RGBA.white.relativeLuminance - 1) < 0.000_001)
    }

    @Test func `uses the linear segment for very dark channels`() {
        // 0.03 is below the 0.03928 knee, so it's divided by 12.92 rather than gamma-expanded.
        let grey = RGBA(red: 0.03, green: 0.03, blue: 0.03)
        #expect(abs(grey.relativeLuminance - 0.03 / 12.92) < 0.000_001)
    }

    @Test func `weights green most heavily`() {
        #expect(RGBA(red: 0, green: 1, blue: 0).relativeLuminance > RGBA(red: 1, green: 0, blue: 0).relativeLuminance)
    }
}

enum RGBATests {
    struct Hex {
        let colour = RGBA(hex: 0x336699)

        @Test func `reads the red byte`() {
            #expect(abs(colour.red - 0x33 / 255.0) < 0.000_001)
        }

        @Test func `reads the green byte`() {
            #expect(abs(colour.green - 0x66 / 255.0) < 0.000_001)
        }

        @Test func `reads the blue byte`() {
            #expect(abs(colour.blue - 0x99 / 255.0) < 0.000_001)
        }

        @Test func `is opaque by default`() {
            #expect(colour.alpha == 1)
        }
    }

    struct Clamping {
        @Test func `clamps channels above one`() {
            #expect(RGBA(red: 2, green: 0, blue: 0).red == 1)
        }

        @Test func `clamps channels below zero`() {
            #expect(RGBA(red: -1, green: 0, blue: 0).red == 0)
        }

        @Test func `clamps alpha`() {
            #expect(RGBA(red: 0, green: 0, blue: 0, alpha: 5).alpha == 1)
        }
    }

    struct Over {
        @Test func `an opaque colour hides the background`() {
            #expect(RGBA(hex: 0x123456).over(.white) == RGBA(hex: 0x123456))
        }

        @Test func `a transparent colour shows the background`() {
            #expect(RGBA(hex: 0x123456, alpha: 0).over(.white) == .white)
        }

        @Test func `half alpha white over black is mid grey`() {
            #expect(RGBA(hex: 0xFFFFFF, alpha: 0.5).over(.black) == RGBA(red: 0.5, green: 0.5, blue: 0.5))
        }

        @Test func `the result is opaque`() {
            #expect(RGBA(hex: 0xFFFFFF, alpha: 0.2).over(.black).alpha == 1)
        }
    }
}
