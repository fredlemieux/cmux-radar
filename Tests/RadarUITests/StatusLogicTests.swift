// MUTATION-VERIFIED: killed 3/3 mutants on 2026-11-19 (Logic/StatusLogic.swift)
@testable import RadarUI
import Testing

struct DotTreatmentTests {
    @Test func `every status has its own shape`() {
        #expect(Set(SessionStatus.allCases.map(dotTreatment(for:))).count == SessionStatus.allCases.count)
    }

    @Test func `waiting gets a halo`() {
        #expect(dotTreatment(for: .waiting) == .halo)
    }

    @Test func `permission gets a ring`() {
        #expect(dotTreatment(for: .permission) == .ring)
    }

    @Test func `working is solid`() {
        #expect(dotTreatment(for: .working) == .solid)
    }

    @Test func `idle is hollow`() {
        #expect(dotTreatment(for: .idle) == .hollow)
    }
}

struct ShouldPulseTests {
    @Test(arguments: [SessionStatus.waiting, .permission])
    func `pulses an attention status when asked`(status: SessionStatus) {
        #expect(shouldPulse(pulsing: true, status: status, reduceMotion: false))
    }

    @Test func `does not pulse when not asked`() {
        #expect(!shouldPulse(pulsing: false, status: .waiting, reduceMotion: false))
    }

    @Test(arguments: [SessionStatus.working, .idle])
    func `never pulses a quiet status`(status: SessionStatus) {
        #expect(!shouldPulse(pulsing: true, status: status, reduceMotion: false))
    }

    @Test func `never pulses with reduce motion on`() {
        #expect(!shouldPulse(pulsing: true, status: .waiting, reduceMotion: true))
    }
}

struct ProgressAccessibilityValueTests {
    @Test func `reads a fraction as a whole percent`() {
        #expect(progressAccessibilityValue(0.424) == "42 percent")
    }

    @Test func `rounds half up`() {
        #expect(progressAccessibilityValue(0.425) == "43 percent")
    }

    @Test func `clamps out-of-range values`() {
        #expect(progressAccessibilityValue(1.7) == "100 percent")
    }
}

struct SectionLabelColourTests {
    @Test(arguments: [SessionStatus.waiting, .permission, .working])
    func `uses the status colour for active groups`(status: SessionStatus) {
        #expect(sectionLabelUsesStatusColor(status))
    }

    @Test func `uses tertiary text for idle`() {
        #expect(!sectionLabelUsesStatusColor(.idle))
    }
}

struct ReducesMotionTests {
    @Test func `follows the system when it reduces motion`() {
        #expect(reducesMotion(.system, system: true))
    }

    @Test func `follows the system when it allows motion`() {
        #expect(!reducesMotion(.system, system: false))
    }

    @Test func `reduced always reduces`() {
        #expect(reducesMotion(.reduced, system: false))
    }

    @Test func `full never reduces`() {
        #expect(!reducesMotion(.full, system: true))
    }
}
