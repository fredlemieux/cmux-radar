// MUTATION-VERIFIED: killed 10/10 mutants on 2026-11-19 (Actions.swift)
import Foundation
import PropertyBased
@testable import RadarCore
import Testing

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

        @Test func `is never allowed while working, whatever the reply`() async {
            await propertyCheck(input: Gen.lowercaseLetter.string(of: 0 ... 20)) { text in
                #expect(!isAllowed(.reply(text), on: session("s", .working), now: epoch))
            }
        }
    }

    struct Permission {
        let open = session("s", .needsPermission, pending: permission, pendingSince: epoch)

        @Test func `allow is allowed while the request is held`() {
            #expect(isAllowed(.allow(.once), on: open, now: at(60)))
        }

        @Test func `deny is allowed while the request is held`() {
            #expect(isAllowed(.deny(message: nil), on: open, now: at(60)))
        }

        @Test func `allow is still allowed at exactly the timeout`() {
            #expect(isAllowed(.allow(.always), on: open, now: at(Policy.standard.pendingTimeout)))
        }

        @Test func `allow is refused once the request timed out`() {
            #expect(!isAllowed(.allow(.once), on: open, now: at(Policy.standard.pendingTimeout + 1)))
        }

        @Test func `allow is refused without an open request`() {
            #expect(!isAllowed(.allow(.once), on: session("s", .needsPermission), now: epoch))
        }

        @Test func `allow is refused for a question`() {
            #expect(!isAllowed(.allow(.once), on: session("s", .needsAnswer, pending: question, pendingSince: epoch), now: epoch))
        }

        @Test func `uses the given policy`() {
            let quick = Policy(idleAfter: 10, hideEndedAfter: 10, pendingTimeout: 10)
            #expect(!isAllowed(.allow(.once), on: open, now: at(11), policy: quick))
        }
    }

    struct Answer {
        @Test func `is allowed for an open question`() {
            #expect(isAllowed(
                .answer(optionIDs: ["a"]),
                on: session("s", .needsAnswer, pending: question, pendingSince: epoch),
                now: epoch,
            ))
        }

        @Test func `is refused for a permission request`() {
            let open = session("s", .needsPermission, pending: permission, pendingSince: epoch)
            #expect(!isAllowed(.answer(optionIDs: ["a"]), on: open, now: epoch))
        }
    }

    struct Plan {
        let open = session("s", .needsPlanApproval, pending: plan, pendingSince: epoch)

        @Test func `approval is allowed for an open plan`() {
            #expect(isAllowed(.approvePlan, on: open, now: epoch))
        }

        @Test func `rejection is allowed for an open plan`() {
            #expect(isAllowed(.rejectPlan(feedback: "smaller steps"), on: open, now: epoch))
        }

        @Test func `approval is refused for a question`() {
            #expect(!isAllowed(.approvePlan, on: session("s", .needsAnswer, pending: question, pendingSince: epoch), now: epoch))
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

    @Test func `is false at exactly the timeout`() {
        let open = session("s", .needsAnswer, pending: question, pendingSince: epoch)
        #expect(!isPendingExpired(open, now: at(Policy.standard.pendingTimeout)))
    }

    @Test func `is true after the timeout`() {
        let open = session("s", .needsAnswer, pending: question, pendingSince: epoch)
        #expect(isPendingExpired(open, now: at(Policy.standard.pendingTimeout + 1)))
    }
}
