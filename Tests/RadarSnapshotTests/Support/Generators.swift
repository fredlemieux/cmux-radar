import PropertyBased
import RadarSnapshot

// Seeds are random per run; a failing property prints its seed. Reproduce locally with the
// library's fixed-seed test trait and never commit it (SwiftLint rule `no_committed_fixed_seed`).
// See docs/adr/0003.

let maxSide = 6
let maxBytes = maxSide * maxSide * Bitmap.bytesPerPixel

/// Bitmap dimensions plus enough random bytes to fill the largest one.
let bitmapInputs = (
    width: Gen.int(in: 1 ... maxSide),
    height: Gen.int(in: 1 ... maxSide),
    bytes: Gen.uint8().array(of: maxBytes),
)

/// Builds a bitmap from generated parts. Forces alpha to 255 when `opaque` is set, because
/// premultiplied encoders legitimately alter colour channels of translucent pixels.
func makeBitmap(width: Int, height: Int, bytes: [UInt8], opaque: Bool = false) -> Bitmap? {
    var pixels = Array(bytes.prefix(width * height * Bitmap.bytesPerPixel))
    if opaque {
        for index in stride(from: 3, to: pixels.count, by: Bitmap.bytesPerPixel) {
            pixels[index] = 255
        }
    }
    return Bitmap(width: width, height: height, pixels: pixels)
}

/// A single-colour bitmap.
func solid(width: Int, height: Int, rgba: [UInt8]) -> Bitmap? {
    Bitmap(width: width, height: height, pixels: Array([[UInt8]](repeating: rgba, count: width * height).joined()))
}
