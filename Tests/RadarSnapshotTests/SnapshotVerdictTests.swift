// MUTATION-VERIFIED: killed 1/1 mutants on 2026-11-19
import RadarSnapshot
import Testing

struct JudgeSnapshotTests {
    // 10 pixels; `oneOff` differs from `base` in exactly one pixel (10%).
    let base = Bitmap(width: 10, height: 1, pixels: Array(repeating: 0, count: 40))
    let oneOff = Bitmap(width: 10, height: 1, pixels: [200, 0, 0, 0] + Array(repeating: 0, count: 36))

    struct WhenRecording {
        let parent = JudgeSnapshotTests()

        @Test func `forced recording wins over a matching reference`() throws {
            let image = try #require(parent.base)
            let verdict = judgeSnapshot(reference: image, actual: image, record: true, precision: 1, tolerance: 0)
            #expect(verdict == .recorded(.recordingForced))
        }

        @Test func `missing reference is recorded`() throws {
            let verdict = try judgeSnapshot(reference: nil, actual: #require(parent.base), record: false, precision: 1, tolerance: 0)
            #expect(verdict == .recorded(.missingReference))
        }
    }

    struct WhenComparing {
        let parent = JudgeSnapshotTests()

        @Test func `identical images match`() throws {
            let image = try #require(parent.base)
            #expect(judgeSnapshot(reference: image, actual: image, record: false, precision: 1, tolerance: 0) == .matched)
        }

        @Test func `difference within precision matches`() throws {
            let reference = try #require(parent.base)
            let actual = try #require(parent.oneOff)
            let verdict = judgeSnapshot(reference: reference, actual: actual, record: false, precision: 0.9, tolerance: 0)
            #expect(verdict == .matched)
        }

        @Test func `difference beyond precision mismatches`() throws {
            let reference = try #require(parent.base)
            let actual = try #require(parent.oneOff)
            let verdict = judgeSnapshot(reference: reference, actual: actual, record: false, precision: 0.95, tolerance: 0)
            #expect(verdict == .mismatched(differingFraction: 0.1))
        }

        @Test func `tolerance absorbs small channel differences`() throws {
            let reference = try #require(parent.base)
            let actual = try #require(parent.oneOff)
            let verdict = judgeSnapshot(reference: reference, actual: actual, record: false, precision: 1, tolerance: 200)
            #expect(verdict == .matched)
        }
    }
}
