// MUTATION-VERIFIED: killed 8/8 mutants on 2026-11-19 (Logic/SessionOrdering.swift)
import PropertyBased
@testable import RadarUI
import Testing

private func session(_ id: String, _ status: SessionStatus) -> SessionCardModel {
    SessionCardModel(id: id, name: id, age: "1m", status: status)
}

private let statuses = Gen.element(of: SessionStatus.allCases).compactMap(\.self).array(of: 0 ... 12)

private func sessions(_ list: [SessionStatus]) -> [SessionCardModel] {
    list.enumerated().map { session("s\($0.offset)", $0.element) }
}

struct SortedByUrgencyTests {
    struct Properties {
        @Test func `keeps every session`() async {
            await propertyCheck(input: statuses) { list in
                let input = sessions(list)
                #expect(Set(sortedByUrgency(input).map(\.id)) == Set(input.map(\.id)))
            }
        }

        @Test func `never puts a less urgent session first`() async {
            await propertyCheck(input: statuses) { list in
                let ranks = sortedByUrgency(sessions(list)).map { urgencyRank($0.status) }
                #expect(ranks == ranks.sorted())
            }
        }

        @Test func `keeps arrival order within a status`() async {
            await propertyCheck(input: statuses) { list in
                let input = sessions(list)
                let sorted = sortedByUrgency(input)
                for status in SessionStatus.allCases {
                    #expect(sorted.filter { $0.status == status }.map(\.id) == input.filter { $0.status == status }.map(\.id))
                }
            }
        }
    }

    @Test func `orders permission, waiting, working, idle`() {
        let input = [session("i", .idle), session("w", .working), session("q", .waiting), session("p", .permission)]
        #expect(sortedByUrgency(input).map(\.id) == ["p", "q", "w", "i"])
    }
}

struct SummaryLineTests {
    @Test func `says all quiet when nothing is running`() {
        #expect(summaryLine(StatusSummary()) == "All quiet")
    }

    @Test func `uses the singular for one session needing you`() {
        #expect(summaryLine(StatusSummary(waiting: 1)) == "1 needs you")
    }

    @Test func `counts waiting and permission together as needing you`() {
        #expect(summaryLine(StatusSummary(waiting: 1, permission: 1)) == "2 need you")
    }

    @Test func `lists every non-empty group`() {
        #expect(summaryLine(StatusSummary(waiting: 2, working: 1, idle: 3)) == "2 need you · 1 working · 3 idle")
    }

    @Test func `omits empty groups`() {
        #expect(summaryLine(StatusSummary(idle: 3)) == "3 idle")
    }
}

struct StatusSummaryTests {
    let summary = StatusSummary([
        session("a", .waiting), session("b", .waiting), session("c", .permission), session("d", .working), session("e", .idle),
    ])

    @Test func `counts waiting sessions`() {
        #expect(summary.waiting == 2)
    }

    @Test func `counts permission sessions`() {
        #expect(summary.permission == 1)
    }

    @Test func `counts working sessions`() {
        #expect(summary.working == 1)
    }

    @Test func `counts idle sessions`() {
        #expect(summary.idle == 1)
    }

    @Test func `needing you is waiting plus permission`() {
        #expect(summary.needingYou == 3)
    }
}

struct NormalisedReplyTests {
    @Test func `trims surrounding whitespace`() {
        #expect(normalisedReply("  ship it \n") == "ship it")
    }

    @Test func `refuses an empty reply`() {
        #expect(normalisedReply("") == nil)
    }

    @Test func `refuses a whitespace-only reply`() {
        #expect(normalisedReply("   \n\t") == nil)
    }

    @Test func `keeps inner whitespace`() {
        #expect(normalisedReply("a  b") == "a  b")
    }
}

struct NeedVerbTests {
    @Test func `is singular for one`() {
        #expect(needVerb(for: 1) == "needs")
    }

    @Test func `is plural for two`() {
        #expect(needVerb(for: 2) == "need")
    }
}
