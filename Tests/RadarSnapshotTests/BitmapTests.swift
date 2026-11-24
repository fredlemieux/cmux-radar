// MUTATION-VERIFIED: killed 3/3 mutants on 2026-11-19
import RadarSnapshot
import Testing

enum BitmapTests {
    struct Init {
        @Test func `accepts exact byte count`() {
            #expect(Bitmap(width: 2, height: 3, pixels: Array(repeating: 0, count: 24)) != nil)
        }

        @Test func `rejects too few bytes`() {
            #expect(Bitmap(width: 2, height: 3, pixels: Array(repeating: 0, count: 23)) == nil)
        }

        @Test func `rejects too many bytes`() {
            #expect(Bitmap(width: 2, height: 3, pixels: Array(repeating: 0, count: 25)) == nil)
        }

        @Test func `rejects zero width`() {
            #expect(Bitmap(width: 0, height: 3, pixels: []) == nil)
        }

        @Test func `rejects zero height`() {
            #expect(Bitmap(width: 3, height: 0, pixels: []) == nil)
        }
    }

    struct PixelAccess {
        let bitmap = Bitmap(width: 2, height: 1, pixels: [1, 2, 3, 4, 5, 6, 7, 8])

        @Test func `counts pixels`() {
            #expect(bitmap?.pixelCount == 2)
        }

        @Test func `returns first pixel channels`() {
            #expect(bitmap.map { Array($0.rgba(at: 0)) } == [1, 2, 3, 4])
        }

        @Test func `returns second pixel channels`() {
            #expect(bitmap.map { Array($0.rgba(at: 1)) } == [5, 6, 7, 8])
        }
    }
}
