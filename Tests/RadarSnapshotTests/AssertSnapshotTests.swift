// MUTATION-VERIFIED: n/a — file-system glue is excluded from mutation (docs/adr/0002); verified by example
import Foundation
import RadarSnapshot
import SwiftUI
import Testing

/// Drives `assertSnapshot` against a throwaway directory, as if the test file lived there.
@MainActor
struct AssertSnapshotTests {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("radar-snapshot-\(UUID().uuidString)").path
    var testFile: String {
        "\(directory)/FakeTests.swift"
    }

    var darkReference: String {
        "\(directory)/__Snapshots__/FakeTests/swatch.dark.png"
    }

    var darkFailure: String {
        "\(directory)/__Snapshots__/FakeTests/swatch.dark.failure.png"
    }

    let size = CGSize(width: 4, height: 4)

    func snapshot(_ color: Color, scheme: ColorScheme = .dark, record: Bool = false) {
        assertSnapshot(of: color, size: size, named: "swatch", colorScheme: scheme, record: record, filePath: testFile)
    }

    func exists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    @MainActor
    struct WhenTheReferenceIsMissing {
        let context = AssertSnapshotTests()

        @Test func `fails the test`() {
            withKnownIssue { context.snapshot(.red) }
        }

        @Test func `writes the reference`() {
            withKnownIssue { context.snapshot(.red) }
            #expect(context.exists(context.darkReference))
        }

        @Test func `names a light reference with the light suffix`() {
            withKnownIssue { context.snapshot(.red, scheme: .light) }
            #expect(context.exists("\(context.directory)/__Snapshots__/FakeTests/swatch.light.png"))
        }
    }

    @MainActor
    struct WhenTheReferenceMatches {
        let context = AssertSnapshotTests()

        init() {
            withKnownIssue { context.snapshot(.red) }
        }

        @Test func `passes`() {
            context.snapshot(.red)
        }

        @Test func `removes a stale failure image`() throws {
            try FileManager.default.createDirectory(
                atPath: "\(context.directory)/__Snapshots__/FakeTests",
                withIntermediateDirectories: true,
            )
            FileManager.default.createFile(atPath: context.darkFailure, contents: Data([1]))
            context.snapshot(.red)
            #expect(!context.exists(context.darkFailure))
        }
    }

    @MainActor
    struct WhenTheReferenceDiffers {
        let context = AssertSnapshotTests()

        init() {
            withKnownIssue { context.snapshot(.red) }
        }

        @Test func `fails the test`() {
            withKnownIssue { context.snapshot(.blue) }
        }

        @Test func `writes the actual image as a failure`() {
            withKnownIssue { context.snapshot(.blue) }
            #expect(context.exists(context.darkFailure))
        }

        @Test func `keeps the reference unchanged`() {
            let before = FileManager.default.contents(atPath: context.darkReference)
            withKnownIssue { context.snapshot(.blue) }
            #expect(FileManager.default.contents(atPath: context.darkReference) == before)
        }
    }

    @MainActor
    struct WhenTheReferenceIsUnreadable {
        let context = AssertSnapshotTests()
        let garbage = Data("<<<<<<< HEAD".utf8)

        init() throws {
            try FileManager.default.createDirectory(
                atPath: "\(context.directory)/__Snapshots__/FakeTests",
                withIntermediateDirectories: true,
            )
            FileManager.default.createFile(atPath: context.darkReference, contents: garbage)
        }

        @Test func `fails the test`() {
            withKnownIssue { context.snapshot(.red) }
        }

        @Test func `does not overwrite the reference`() {
            withKnownIssue { context.snapshot(.red) }
            #expect(FileManager.default.contents(atPath: context.darkReference) == garbage)
        }
    }
}
