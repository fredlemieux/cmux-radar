// MUTATION-VERIFIED: killed 10/10 mutants on 2026-11-19 (Actions.swift)
import Foundation
import PropertyBased
@testable import RadarCore
import Testing

/// The last moment a Feed reply may be sent: the timeout less the safety margin.
private let cutoff = Policy.standard.pendingTimeout - Policy.standard.replyMargin

enum IsAllowedTests {
    struct Reply {
        @Test func `is allowed while waiting`() {
            #expect(isAllowed(.reply("ok"), on: session("s", .waiting), now: epoch))
        }

        @Test func `is allowed while idle`() {
            #expect(isAllowed(.reply("ok"), on: session("s", .idle), now: epoch))
        }

        @Test func `is refused while working`() {
            #expect(!isAllowed(.reply("ok"), on: session("s", .working), now: epoch))
        }

        @Test func `is refused without a surface to type into`() {
            #expect(!isAllowed(.reply("ok"), on: session("s", .waiting, surface: nil), now: epoch))
        }

        @Test func `is refused while a decision is open`() {
            #expect(!isAllowed(.reply("ok"), on: session("s", .needsAnswer, pending: question, pendingSince: epoch), now: epoch))
        }

        @Test func `is allowed exactly between turns with a surface, in every state`() async {
            await propertyCheck(input: anySession, Gen.bool) { start, hasSurface in
                var target = start
                target.surfaceID = hasSurface ? "surface-1" : nil
                let betweenTurns = target.state == .waiting || target.state == .idle
                #expect(isAllowed(.reply("ok"), on: target, now: epoch) == (betweenTurns && hasSurface))
            }
        }
    }

    struct Permission {
        let open = session("s", .needsPermission, pending: permission, pendingSince: epoch)

        @Test func `allow is allowed while the request is held`() {
            #expect(isAllowed(.allow(.once, requestID: "req-1"), on: open, now: at(60)))
        }

        @Test func `deny is allowed while the request is held`() {
            #expect(isAllowed(.deny(message: nil, requestID: "req-1"), on: open, now: at(60)))
        }

        @Test func `allow is still allowed at exactly the reply cut-off`() {
            #expect(isAllowed(.allow(.always, requestID: "req-1"), on: open, now: at(cutoff)))
        }

        @Test func `allow is refused inside the safety margin before the timeout`() {
            #expect(!isAllowed(.allow(.once, requestID: "req-1"), on: open, now: at(cutoff + 1)))
        }

        @Test func `deny is refused inside the safety margin`() {
            #expect(!isAllowed(.deny(message: nil, requestID: "req-1"), on: open, now: at(cutoff + 1)))
        }

        @Test func `allow is refused for a request that replaced the one shown`() {
            #expect(!isAllowed(.allow(.once, requestID: "req-old"), on: open, now: epoch))
        }

        @Test func `allow is refused without an open request`() {
            #expect(!isAllowed(.allow(.once, requestID: "req-1"), on: session("s", .needsPermission), now: epoch))
        }

        @Test func `allow is refused for a question`() {
            #expect(!isAllowed(
                .allow(.once, requestID: "req-1"),
                on: session("s", .needsAnswer, pending: question, pendingSince: epoch),
                now: epoch,
            ))
        }

        @Test func `uses the given policy`() {
            let quick = Policy(idleAfter: 10, hideEndedAfter: 10, pendingTimeout: 10, replyMargin: 0)
            #expect(!isAllowed(.allow(.once, requestID: "req-1"), on: open, now: at(11), policy: quick))
        }
    }

    struct Answer {
        @Test func `is allowed for an open question`() {
            #expect(isAllowed(
                .answer(optionIDs: ["a"], requestID: "req-2"),
                on: session("s", .needsAnswer, pending: question, pendingSince: epoch),
                now: epoch,
            ))
        }

        @Test func `is refused for another question`() {
            let open = session("s", .needsAnswer, pending: question, pendingSince: epoch)
            #expect(!isAllowed(.answer(optionIDs: ["a"], requestID: "req-old"), on: open, now: epoch))
        }

        @Test func `is refused inside the safety margin`() {
            let open = session("s", .needsAnswer, pending: question, pendingSince: epoch)
            #expect(!isAllowed(.answer(optionIDs: ["a"], requestID: "req-2"), on: open, now: at(cutoff + 1)))
        }

        @Test func `is refused for a permission request`() {
            let open = session("s", .needsPermission, pending: permission, pendingSince: epoch)
            #expect(!isAllowed(.answer(optionIDs: ["a"], requestID: "req-2"), on: open, now: epoch))
        }
    }

    struct Plan {
        let open = session("s", .needsPlanApproval, pending: plan, pendingSince: epoch)

        @Test func `approval is allowed for an open plan`() {
            #expect(isAllowed(.approvePlan(requestID: "req-3"), on: open, now: epoch))
        }

        @Test func `rejection is allowed for an open plan`() {
            #expect(isAllowed(.rejectPlan(feedback: "smaller steps", requestID: "req-3"), on: open, now: epoch))
        }

        @Test func `approval is refused for another plan`() {
            #expect(!isAllowed(.approvePlan(requestID: "req-old"), on: open, now: epoch))
        }

        @Test func `approval is refused inside the safety margin`() {
            #expect(!isAllowed(.approvePlan(requestID: "req-3"), on: open, now: at(cutoff + 1)))
        }

        @Test func `rejection is refused inside the safety margin`() {
            #expect(!isAllowed(.rejectPlan(feedback: nil, requestID: "req-3"), on: open, now: at(cutoff + 1)))
        }

        @Test func `approval is refused for a question`() {
            #expect(!isAllowed(
                .approvePlan(requestID: "req-3"),
                on: session("s", .needsAnswer, pending: question, pendingSince: epoch),
                now: epoch,
            ))
        }
    }

    struct Jump {
        @Test func `is always allowed`() async {
            await propertyCheck(input: anySession, Gen.double(in: 0 ... 100_000)) { session, seconds in
                #expect(isAllowed(.jump, on: session, now: at(seconds)))
            }
        }
    }
}

struct IsPendingExpiredTests {
    @Test func `is false without a decision`() {
        #expect(!isPendingExpired(session("s", .waiting), now: at(1_000_000)))
    }

    @Test func `is false at exactly the reply cut-off`() {
        let open = session("s", .needsAnswer, pending: question, pendingSince: epoch)
        #expect(!isPendingExpired(open, now: at(cutoff)))
    }

    @Test func `is true inside the safety margin before the timeout`() {
        let open = session("s", .needsAnswer, pending: question, pendingSince: epoch)
        #expect(isPendingExpired(open, now: at(cutoff + 1)))
    }
}
