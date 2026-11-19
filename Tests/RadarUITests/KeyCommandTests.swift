import RadarStories

// MUTATION-VERIFIED: killed 4/4 mutants on 2026-11-19 (Logic/KeyCommands.swift)
@testable import RadarUI
import Testing

struct KeyCommandTests {
    @Test(arguments: 1 ... 9)
    func `command and a digit picks that reply`(digit: Int) {
        #expect(keyCommand(characters: String(digit), isReturn: false, command: true, option: false) == .pick(digit))
    }

    @Test func `a digit without command does nothing`() {
        #expect(keyCommand(characters: "1", isReturn: false, command: false, option: false) == nil)
    }

    @Test func `command zero does nothing`() {
        #expect(keyCommand(characters: "0", isReturn: false, command: true, option: false) == nil)
    }

    @Test func `command and a letter does nothing`() {
        #expect(keyCommand(characters: "a", isReturn: false, command: true, option: false) == nil)
    }

    @Test func `option return jumps`() {
        #expect(keyCommand(characters: "\r", isReturn: true, command: false, option: true) == .jump)
    }

    @Test func `plain return is left to the focused control`() {
        #expect(keyCommand(characters: "\r", isReturn: true, command: false, option: false) == nil)
    }
}

struct QuickReplyTests {
    let session = SessionCardModel(
        id: "s",
        name: "s",
        age: "1m",
        status: .waiting,
        replies: [ReplyOption(index: 1, label: "Yes"), ReplyOption(index: 2, label: "No")],
    )

    @Test func `finds the reply with that number`() {
        #expect(quickReply(2, in: session)?.label == "No")
    }

    @Test func `returns nothing for a number without a reply`() {
        #expect(quickReply(3, in: session) == nil)
    }

    @Test func `returns nothing when the session can't take a reply`() {
        let blocked = SessionCardModel(id: "s", name: "s", age: "1m", status: .waiting, replies: session.replies, canReply: false)
        #expect(quickReply(1, in: blocked) == nil)
    }

    @Test(arguments: [SessionStatus.permission, .working, .idle])
    func `returns nothing unless the session is waiting`(status: SessionStatus) {
        let other = SessionCardModel(id: "s", name: "s", age: "1m", status: status, replies: session.replies)
        #expect(quickReply(1, in: other) == nil)
    }
}

struct RouteTests {
    let first = SampleSessions.waiting
    let second = SampleSessions.waitingNoReplies

    @Test func `picks on the focused session, not the first one`() {
        let other = SessionCardModel(
            id: "other",
            name: "other",
            age: "1m",
            status: .waiting,
            replies: [ReplyOption(index: 1, label: "Yes")],
        )
        #expect(route(.pick(1), focused: "other", in: [first, other]) == .pick(sessionID: "other", ReplyOption(index: 1, label: "Yes")))
    }

    @Test func `jumps to the focused session`() {
        #expect(route(.jump, focused: second.id, in: [first, second]) == .jump(sessionID: second.id))
    }

    @Test func `does nothing when no card is focused`() {
        #expect(route(.jump, focused: nil, in: [first, second]) == nil)
    }

    @Test func `does nothing when the focused session is gone`() {
        #expect(route(.jump, focused: "gone", in: [first, second]) == nil)
    }

    @Test func `does nothing when the focused session has no such reply`() {
        #expect(route(.pick(1), focused: second.id, in: [first, second]) == nil)
    }
}

struct SessionLookupTests {
    @Test func `finds the session with that id`() {
        #expect(session(SampleSessions.idle.id, in: SampleSessions.typical)?.id == SampleSessions.idle.id)
    }

    @Test func `is nil for an unknown id`() {
        #expect(session("gone", in: SampleSessions.typical) == nil)
    }
}
