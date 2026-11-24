// MUTATION-VERIFIED: n/a — catalog support code, excluded from mutation; verified by example
import RadarStories
import Testing

@MainActor
struct StoryContextTests {
    let root = StoryContext()
    var context: StoryContext {
        root.scoped(to: "atoms/ReplyChip/Default")
    }

    @Test func `records a tap`() {
        let tap: () -> Void = context.action("pick 1")
        tap()
        #expect(root.log.map(\.name) == ["pick 1"])
    }

    @Test func `records which story the tap came from`() {
        let tap: () -> Void = context.action("pick 1")
        tap()
        #expect(root.log.first?.story == "atoms/ReplyChip/Default")
    }

    @Test func `records the value passed to the action`() {
        let reply: (String) -> Void = context.action("reply")
        reply("Build it")
        #expect(root.log.first?.detail == "Build it")
    }

    @Test func `lists the newest action first`() {
        let first: () -> Void = context.action("first")
        let second: () -> Void = context.action("second")
        first()
        second()
        #expect(root.log.map(\.name) == ["second", "first"])
    }

    @Test func `gives every action a distinct id`() {
        let tap: () -> Void = context.action("tap")
        tap()
        tap()
        #expect(Set(root.log.map(\.id)).count == 2)
    }

    @Test func `clears the log from a scoped child`() {
        let child = context
        let tap: () -> Void = child.action("tap")
        tap()
        child.clear()
        #expect(root.log.isEmpty)
    }

    @Test func `attributes actions to their own story`() {
        let other = root.scoped(to: "atoms/ActionButton/Primary")
        let first: () -> Void = context.action("pick 1")
        let second: () -> Void = other.action("allow once")
        first()
        second()
        #expect(root.log.map(\.story) == ["atoms/ActionButton/Primary", "atoms/ReplyChip/Default"])
    }

    @Test func `a silent context records nothing`() {
        let silent = StoryContext.silent
        let tap: () -> Void = silent.action("tap")
        tap()
        #expect(silent.log.isEmpty)
    }

    @Test func `keeps a root alive that only its children reference`() {
        weak var probe: StoryContext?
        let child: StoryContext
        do {
            let root = StoryContext()
            probe = root
            child = root.scoped(to: "atoms/ReplyChip/Default")
        }
        withExtendedLifetime(child) {
            #expect(probe != nil)
        }
    }
}
