// MUTATION-VERIFIED: killed 2/2 mutants on 2026-11-19
import Foundation
import PropertyBased
import RadarSnapshot
import Testing

struct PNGCodecTests {
    @Test func `opaque bitmaps survive A round trip`() async {
        await propertyCheck(input: bitmapInputs.width, bitmapInputs.height, bitmapInputs.bytes) { width, height, bytes in
            let bitmap = try #require(makeBitmap(width: width, height: height, bytes: bytes, opaque: true))
            let data = try #require(PNGCodec.encode(bitmap))
            #expect(PNGCodec.decode(data) == bitmap)
        }
    }

    @Test func `garbage data does not decode`() {
        #expect(PNGCodec.decode(Data([1, 2, 3])) == nil)
    }
}
