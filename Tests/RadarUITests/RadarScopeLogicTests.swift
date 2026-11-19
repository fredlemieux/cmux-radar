// MUTATION-VERIFIED: killed 10/10 mutants on 2026-11-19 (Logic/RadarScopeLogic.swift)
import CoreGraphics
import PropertyBased
@testable import RadarUI
import Testing

private func session(_ id: String, _ status: SessionStatus, progress: Double? = nil) -> SessionCardModel {
    SessionCardModel(id: id, name: id, age: "1m", status: status, progress: progress)
}

struct NeedsYouTests {
    @Test func `a question needs you`() {
        #expect(needsYou(.waiting))
    }

    @Test func `a permission request needs you`() {
        #expect(needsYou(.permission))
    }

    @Test func `working does not`() {
        #expect(!needsYou(.working))
    }

    @Test func `idle does not`() {
        #expect(!needsYou(.idle))
    }
}

struct BlipBearingTests {
    /// Reference values computed independently (FNV-1a 32-bit, then % 3600 / 10).
    @Test(arguments: [("api-gateway", 209.6), ("billing-migration", 218.1), ("", 186.1), ("a", 142.0)])
    func `matches the reference fnv-1a bearing`(id: String, bearing: Double) {
        #expect(abs(blipBearing(for: id) - bearing) < 0.000_1)
    }

    @Test func `stays on the compass`() async {
        await propertyCheck(input: Gen.lowercaseLetter.string(of: 0 ... 30)) { id in
            #expect((0 ..< 360).contains(blipBearing(for: id)))
        }
    }
}

struct BlipRangeTests {
    @Test func `the more a session needs you, the closer to the centre`() {
        let ranges = [SessionStatus.permission, .waiting, .working, .idle].map(blipRange)
        #expect(ranges == ranges.sorted())
    }

    @Test(arguments: SessionStatus.allCases)
    func `stays inside the scope`(status: SessionStatus) {
        #expect((0 ... 1).contains(blipRange(for: status)))
    }

    @Test func `permission and waiting sit on different rings`() {
        #expect(blipRange(for: .permission) != blipRange(for: .waiting))
    }
}

struct BlipOffsetTests {
    @Test func `north is straight up`() {
        let offset = blipOffset(bearing: 0, range: 0.5, radius: 100)
        #expect(abs(offset.width) < 0.000_1 && abs(offset.height + 50) < 0.000_1)
    }

    @Test func `east is to the right`() {
        let offset = blipOffset(bearing: 90, range: 1, radius: 100)
        #expect(abs(offset.width - 100) < 0.000_1 && abs(offset.height) < 0.000_1)
    }

    @Test func `sits at its range from the centre`() async {
        await propertyCheck(input: Gen.double(in: 0 ..< 360), Gen.double(in: 0 ... 1)) { bearing, range in
            let offset = blipOffset(bearing: bearing, range: range, radius: 100)
            #expect(abs((offset.width * offset.width + offset.height * offset.height).squareRoot() - range * 100) < 0.000_1)
        }
    }
}

struct BlipTagTests {
    @Test func `marks a question`() {
        #expect(blipTag(for: session("api", .waiting)) == "API ▲Q")
    }

    @Test func `marks a permission request`() {
        #expect(blipTag(for: session("api", .permission)) == "API ▲PERM")
    }

    @Test func `shows working progress`() {
        #expect(blipTag(for: session("api", .working, progress: 0.72)) == "API ›› 72%")
    }

    @Test func `shows working without progress`() {
        #expect(blipTag(for: session("api", .working)) == "API ››")
    }

    @Test func `shows only the name when idle`() {
        #expect(blipTag(for: session("api", .idle)) == "API")
    }
}

struct ScopeHeadlineTests {
    @Test func `counts sessions calling in`() {
        #expect(scopeHeadline(StatusSummary(waiting: 1, permission: 1, working: 3)) == "2 INBOUND")
    }

    @Test func `is all clear when nobody needs you`() {
        #expect(scopeHeadline(StatusSummary(working: 3, idle: 1)) == "ALL CLEAR")
    }
}

struct ContactTests {
    let sessions = [session("w", .waiting), session("p", .permission), session("x", .working)]

    @Test func `defaults to the most urgent caller`() {
        #expect(contact(selected: nil, in: sessions)?.id == "p")
    }

    @Test func `keeps the selected caller`() {
        #expect(contact(selected: "w", in: sessions)?.id == "w")
    }

    @Test func `ignores a selection that no longer needs you`() {
        #expect(contact(selected: "x", in: sessions)?.id == "p")
    }

    @Test func `is empty when nobody needs you`() {
        #expect(contact(selected: nil, in: [session("x", .working)]) == nil)
    }
}

struct NextContactTests {
    let sessions = [session("w", .waiting), session("p", .permission), session("x", .working)]

    @Test func `moves to the next caller`() {
        #expect(nextContact(after: "p", in: sessions) == "w")
    }

    @Test func `wraps round to the first`() {
        #expect(nextContact(after: "w", in: sessions) == "p")
    }

    @Test func `starts at the most urgent without a current one`() {
        #expect(nextContact(after: nil, in: sessions) == "p")
    }

    @Test func `is nil when nobody needs you`() {
        #expect(nextContact(after: nil, in: [session("x", .working)]) == nil)
    }
}

struct ProgressSuffixTests {
    @Test func `is empty without progress`() {
        #expect(progressSuffix(nil).isEmpty)
    }

    @Test func `rounds to a whole percent`() {
        #expect(progressSuffix(0.725) == " 73%")
    }

    @Test func `clamps above one`() {
        #expect(progressSuffix(1.4) == " 100%")
    }
}

struct TagLeadsTests {
    @Test func `leads on the right half`() {
        #expect(tagLeads(bearing: 90))
    }

    @Test func `trails on the left half`() {
        #expect(!tagLeads(bearing: 270))
    }

    @Test func `trails from due south`() {
        #expect(!tagLeads(bearing: 180))
    }
}

struct TagNameTests {
    @Test func `capitalises a short name`() {
        #expect(tagName("api") == "API")
    }

    @Test func `keeps a name of exactly twelve characters`() {
        #expect(tagName("twelve-chars") == "TWELVE-CHARS")
    }

    @Test func `shortens a longer name with an ellipsis`() {
        #expect(tagName("billing-migration") == "BILLING-MIG…")
    }
}
