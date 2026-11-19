public import AppKit
public import SwiftUI

/// How a snapshot is drawn.
public nonisolated enum SnapshotRenderer: Sendable {
    /// SwiftUI's `ImageRenderer`. Fast and pure SwiftUI, but it can't draw AppKit-backed
    /// controls such as `TextField` (they come out as a yellow "unsupported" placeholder).
    case image
    /// An offscreen `NSHostingView`, drawn with `cacheDisplay`. Draws AppKit-backed controls.
    case hosted
}

/// Renders `view` in an offscreen `NSHostingView` at `scale`× and returns its pixels.
@MainActor
public func renderHostedBitmap(
    _ view: some View,
    size: CGSize,
    colorScheme: ColorScheme,
    scale: CGFloat = 2,
) -> Bitmap? {
    let host = NSHostingView(rootView: view
        .frame(width: size.width, height: size.height)
        .environment(\.colorScheme, colorScheme))
    host.frame = CGRect(origin: .zero, size: size)
    // A view drawn without a window can miss compositing passes (stray edges around shapes).
    // Host it in an offscreen borderless window and let it display before capturing.
    let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
    window.contentView = host
    host.layoutSubtreeIfNeeded()
    window.displayIfNeeded()
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width * scale),
        pixelsHigh: Int(size.height * scale),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0,
    ) else {
        return nil
    }
    rep.size = size
    host.cacheDisplay(in: host.bounds, to: rep)
    return rep.cgImage.flatMap(PNGCodec.bitmap)
}
