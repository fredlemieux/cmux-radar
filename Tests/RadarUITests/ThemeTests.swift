// MUTATION-VERIFIED: n/a — token values and mappings, no mutable logic; verified by example
@testable import RadarUI
import Testing

struct SessionStatusTests {
    @Test(arguments: [SessionStatus.waiting, .permission])
    func `asks for attention`(status: SessionStatus) {
        #expect(status.needsAttention)
    }

    @Test(arguments: [SessionStatus.working, .idle])
    func `does not ask for attention`(status: SessionStatus) {
        #expect(!status.needsAttention)
    }

    @Test func `every status has a distinct spoken name`() {
        #expect(Set(SessionStatus.allCases.map(\.accessibilityName)).count == SessionStatus.allCases.count)
    }
}

struct PaletteStatusTests {
    @Test(arguments: Appearance.allCases)
    func `gives every status a distinct colour`(appearance: Appearance) {
        let colours = SessionStatus.allCases.map { Palette.classic.status($0).value(for: appearance) }
        #expect(Set(colours.map { "\($0.red),\($0.green),\($0.blue)" }).count == SessionStatus.allCases.count)
    }

    @Test func `maps waiting to the waiting token`() {
        #expect(Palette.classic.status(.waiting) == Palette.classic.statusWaiting)
    }

    @Test func `maps permission to the permission token`() {
        #expect(Palette.classic.status(.permission) == Palette.classic.statusPermission)
    }

    @Test func `maps working to the working token`() {
        #expect(Palette.classic.status(.working) == Palette.classic.statusWorking)
    }

    @Test func `maps idle to the idle token`() {
        #expect(Palette.classic.status(.idle) == Palette.classic.statusIdle)
    }

    @Test func `resolves the dark value in dark mode`() {
        let token = ColorToken(dark: .black, light: .white)
        #expect(token.value(for: .dark) == .black)
    }

    @Test func `resolves the light value in light mode`() {
        let token = ColorToken(dark: .black, light: .white)
        #expect(token.value(for: .light) == .white)
    }
}
