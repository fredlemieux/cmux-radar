// MUTATION-VERIFIED: n/a — story registry glue; verified by example
import RadarSnapshot
import RadarStories
import SwiftUI
import Testing

/// Every story is a snapshot test, in both colour schemes (docs/adr/0002).
/// New story → run `make test` once to record, review the PNG, run again.
@MainActor
struct StorySnapshotTests {
    @Test(arguments: Stories.all, [ColorScheme.dark, .light])
    func `matches its reference image`(story: Story, scheme: ColorScheme) {
        assertSnapshot(of: StoryCanvas(story), size: story.size, named: story.snapshotName, colorScheme: scheme)
    }
}

struct StoryRegistryTests {
    @Test func `every story has a unique id`() {
        #expect(Set(Stories.all.map(\.id)).count == Stories.all.count)
    }

    @Test func `every story has a unique snapshot name`() {
        #expect(Set(Stories.all.map { sanitize($0.snapshotName) }).count == Stories.all.count)
    }

    @Test func `groups stories by component in first-seen order`() {
        let components = Stories.byComponent().map(\.component)
        #expect(components.prefix(3) == ["StatusDot", "CountBadge", "KeyHint"])
    }

    @Test func `keeps every story when grouping`() {
        #expect(Stories.byComponent().flatMap(\.stories).count == Stories.all.count)
    }
}
