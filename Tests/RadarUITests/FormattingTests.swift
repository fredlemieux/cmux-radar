// MUTATION-VERIFIED: killed 3/3 mutants on 2026-11-19 (Logic/Formatting.swift)
import PropertyBased
@testable import RadarUI
import Testing

struct BadgeTextTests {
    @Test func `shows small counts as is`() {
        #expect(badgeText(for: 7) == "7")
    }

    @Test func `shows ninety nine as is`() {
        #expect(badgeText(for: 99) == "99")
    }

    @Test func `caps counts above ninety nine`() {
        #expect(badgeText(for: 100) == "99+")
    }

    @Test func `never shows a negative count`() {
        #expect(badgeText(for: -3) == "0")
    }
}

struct ClampedFractionTests {
    @Test func `always lands in the unit interval`() async {
        await propertyCheck(input: Gen.double(in: -1000 ... 1000)) { value in
            #expect((0 ... 1).contains(clampedFraction(value)))
        }
    }

    @Test func `keeps values already in range`() async {
        await propertyCheck(input: Gen.double(in: 0 ... 1)) { value in
            #expect(clampedFraction(value) == value)
        }
    }

    @Test func `treats nan as zero`() {
        #expect(clampedFraction(.nan) == 0)
    }

    @Test func `treats positive infinity as full`() {
        #expect(clampedFraction(.infinity) == 1)
    }

    @Test func `treats negative infinity as empty`() {
        #expect(clampedFraction(-.infinity) == 0)
    }
}

struct SectionLabelTextTests {
    @Test func `uppercases the title and appends the count`() {
        #expect(sectionLabelText(title: "Needs you", count: 2) == "NEEDS YOU · 2")
    }
}
