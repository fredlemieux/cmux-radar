/// An 8-bit RGBA image held in memory, row-major, four bytes per pixel.
public struct Bitmap: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public let pixels: [UInt8]

    /// Returns `nil` when the byte count doesn't match `width × height × 4`.
    public init?(width: Int, height: Int, pixels: [UInt8]) {
        guard width > 0, height > 0, pixels.count == width * height * Self.bytesPerPixel else {
            return nil
        }
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    public static let bytesPerPixel = 4

    public var pixelCount: Int {
        width * height
    }

    /// The RGBA bytes of the pixel at `index` (row-major).
    public func rgba(at index: Int) -> ArraySlice<UInt8> {
        let start = index * Self.bytesPerPixel
        return pixels[start ..< start + Self.bytesPerPixel]
    }
}
