// MUTATION-VERIFIED: killed 3/3 mutants on 2026-11-19 (Logic/KeyCommands.swift)
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
