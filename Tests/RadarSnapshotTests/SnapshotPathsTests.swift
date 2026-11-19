// MUTATION-VERIFIED: killed 3/3 mutants on 2026-11-19
import RadarSnapshot
import Testing

struct SnapshotPathsTests {
    let paths = snapshotPaths(testFile: "/repo/Tests/UITests/CardTests.swift", name: "waiting.dark")

    @Test func `directory is named after the test file`() {
        #expect(paths.directory == "/repo/Tests/UITests/__Snapshots__/CardTests")
    }

    @Test func `reference is a png named after the snapshot`() {
        #expect(paths.reference == "/repo/Tests/UITests/__Snapshots__/CardTests/waiting.dark.png")
    }

    @Test func `failure sits beside the reference`() {
        #expect(paths.failure == "/repo/Tests/UITests/__Snapshots__/CardTests/waiting.dark.failure.png")
    }

    struct Sanitize {
        @Test func `keeps safe characters`() {
            #expect(sanitize("Card_v2.dark-mode") == "Card_v2.dark-mode")
        }

        @Test func `replaces spaces and slashes`() {
            #expect(sanitize("a b/c") == "a-b-c")
        }

        @Test func `replaces non ASCII letters`() {
            #expect(sanitize("café") == "caf-")
        }
    }
}
