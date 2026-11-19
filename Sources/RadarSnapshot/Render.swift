public import CoreGraphics
public import SwiftUI

/// Renders a SwiftUI view off-screen at a fixed size and colour scheme.
@MainActor
public func renderBitmap(
    _ view: some View,
    size: CGSize,
    colorScheme: ColorScheme,
    scale: CGFloat = 2,
) -> Bitmap? {
    let content = view
        .frame(width: size.width, height: size.height)
        .environment(\.colorScheme, colorScheme)
    let renderer = ImageRenderer(content: content)
    renderer.scale = scale
    guard let image = renderer.cgImage else {
        return nil
    }
    return PNGCodec.bitmap(from: image)
}
