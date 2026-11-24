// MUTATION-VERIFIED: killed 5/5 mutants on 2026-11-19
import PropertyBased
import RadarSnapshot
import Testing

enum PixelDiffTests {
    struct Properties {
        @Test func `an image matches itself`() async {
            await propertyCheck(input: bitmapInputs.width, bitmapInputs.height, bitmapInputs.bytes) { width, height, bytes in
                let bitmap = try #require(makeBitmap(width: width, height: height, bytes: bytes))
                #expect(pixelDiff(bitmap, bitmap, tolerance: 0).differingFraction == 0)
            }
        }

        @Test func `comparison is symmetric`() async {
            await propertyCheck(
                input: bitmapInputs.width,
                bitmapInputs.height,
                bitmapInputs.bytes,
                bitmapInputs.bytes,
            ) { width, height, first, second in
                let lhs = try #require(makeBitmap(width: width, height: height, bytes: first))
                let rhs = try #require(makeBitmap(width: width, height: height, bytes: second))
                #expect(pixelDiff(lhs, rhs, tolerance: 3) == pixelDiff(rhs, lhs, tolerance: 3))
            }
        }

        @Test func `fraction stays within unit interval`() async {
            await propertyCheck(
                input: bitmapInputs.width,
                bitmapInputs.height,
                bitmapInputs.bytes,
                bitmapInputs.bytes,
            ) { width, height, first, second in
                let lhs = try #require(makeBitmap(width: width, height: height, bytes: first))
                let rhs = try #require(makeBitmap(width: width, height: height, bytes: second))
                #expect((0 ... 1).contains(pixelDiff(lhs, rhs, tolerance: 0).differingFraction))
            }
        }

        @Test func `maximum tolerance matches everything`() async {
            await propertyCheck(
                input: bitmapInputs.width,
                bitmapInputs.height,
                bitmapInputs.bytes,
                bitmapInputs.bytes,
            ) { width, height, first, second in
                let lhs = try #require(makeBitmap(width: width, height: height, bytes: first))
                let rhs = try #require(makeBitmap(width: width, height: height, bytes: second))
                #expect(pixelDiff(lhs, rhs, tolerance: .max).differingFraction == 0)
            }
        }
    }

    struct Examples {
        let black = solid(width: 2, height: 2, rgba: [0, 0, 0, 255])
        let nearBlack = solid(width: 2, height: 2, rgba: [5, 0, 0, 255])

        @Test func `different sizes are a size mismatch`() throws {
            let small = try #require(solid(width: 1, height: 1, rgba: [0, 0, 0, 255]))
            #expect(try pixelDiff(#require(black), small, tolerance: 0) == .sizeMismatch)
        }

        @Test func `size mismatch counts as fully different`() {
            #expect(PixelDiff.sizeMismatch.differingFraction == 1)
        }

        @Test func `channel delta above tolerance differs`() throws {
            #expect(try pixelDiff(#require(black), #require(nearBlack), tolerance: 4) == .compared(differing: 4, total: 4))
        }

        @Test func `channel delta equal to tolerance matches`() throws {
            #expect(try pixelDiff(#require(black), #require(nearBlack), tolerance: 5) == .compared(differing: 0, total: 4))
        }

        @Test func `counts only changed pixels`() throws {
            let lhs = try #require(Bitmap(width: 2, height: 1, pixels: [0, 0, 0, 255, 0, 0, 0, 255]))
            let rhs = try #require(Bitmap(width: 2, height: 1, pixels: [0, 0, 0, 255, 9, 0, 0, 255]))
            #expect(pixelDiff(lhs, rhs, tolerance: 0) == .compared(differing: 1, total: 2))
        }

        @Test func `reports fraction of differing pixels`() {
            #expect(PixelDiff.compared(differing: 1, total: 4).differingFraction == 0.25)
        }
    }
}
