// MUTATION-VERIFIED: n/a — no mutable operators in Palette/SessionStatus; verified by example
import RadarUI
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
    @Test(arguments: SessionStatus.allCases)
    func `maps each status to its own token`(status: SessionStatus) {
        let palette = Palette.classic
        let expected: [SessionStatus: ColorToken] = [
            .waiting: palette.statusWaiting,
            .permission: palette.statusPermission,
            .working: palette.statusWorking,
            .idle: palette.statusIdle,
        ]
        #expect(palette.status(status) == expected[status])
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
