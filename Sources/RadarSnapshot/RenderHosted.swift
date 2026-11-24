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

/// The backing scale the hosted renderer's window lays out at: the primary screen's (the one holding
/// the origin, where the offscreen window is placed), or 1 without a screen.
///
/// AppKit snaps positions and glyphs to this grid, so a 1× display (an external monitor, a CI
/// runner) draws edges a fraction of a pixel away from a Retina display, even though the bitmap
/// is always 2×. Within one scale the output is byte-identical across machines.
@MainActor
public func hostedBackingScale() -> CGFloat {
    NSScreen.screens.first?.backingScaleFactor ?? 1
}

/// The reference name for a hosted snapshot: unchanged at 2×, suffixed with the scale otherwise
/// (`card.dark.1x`), so each display scale is compared strictly against its own reference.
public nonisolated func hostedSnapshotName(_ name: String, backingScale: CGFloat) -> String {
    backingScale == 2 ? name : "\(name).\(Int(backingScale))x"
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
    // Host it in an offscreen borderless window; `cacheDisplay` lays it out and draws it.
    let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.contentView = host
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
