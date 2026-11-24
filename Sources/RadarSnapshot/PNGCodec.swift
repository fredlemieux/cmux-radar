public import CoreGraphics
public import Foundation
internal import ImageIO
internal import UniformTypeIdentifiers

/// Converts between `Bitmap` and PNG data via ImageIO, always in sRGB, RGBA8, premultiplied alpha.
public enum PNGCodec {
    public static func encode(_ bitmap: Bitmap) -> Data? {
        guard let image = cgImage(from: bitmap) else {
            return nil
        }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return Data(referencing: data)
    }

    public static func decode(_ data: Data) -> Bitmap? {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            return nil
        }
        return bitmap(from: image)
    }

    /// Redraws any `CGImage` into the canonical sRGB RGBA8 layout.
    public static func bitmap(from image: CGImage) -> Bitmap? {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * Bitmap.bytesPerPixel)
        let drawn = pixels.withUnsafeMutableBytes { buffer in
            guard let context = makeContext(buffer.baseAddress, width: width, height: height) else {
                return false
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? Bitmap(width: width, height: height, pixels: pixels) : nil
    }

    public static func cgImage(from bitmap: Bitmap) -> CGImage? {
        var pixels = bitmap.pixels
        return pixels.withUnsafeMutableBytes { buffer in
            makeContext(buffer.baseAddress, width: bitmap.width, height: bitmap.height)?.makeImage()
        }
    }

    private static func makeContext(_ data: UnsafeMutableRawPointer?, width: Int, height: Int) -> CGContext? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }
        return CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * Bitmap.bytesPerPixel,
            space: space,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue,
        )
    }
}
