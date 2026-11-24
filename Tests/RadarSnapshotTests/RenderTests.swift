// MUTATION-VERIFIED: n/a — rendering glue is excluded from mutation (docs/adr/0002); verified by example
import RadarSnapshot
import SwiftUI
import Testing

@MainActor
struct RenderBitmapTests {
    let size = CGSize(width: 10, height: 5)

    @Test func `renders at twice the requested width`() {
        #expect(renderBitmap(Color.white, size: size, colorScheme: .light)?.width == 20)
    }

    @Test func `renders at twice the requested height`() {
        #expect(renderBitmap(Color.white, size: size, colorScheme: .light)?.height == 10)
    }

    @Test func `honours a custom scale`() {
        #expect(renderBitmap(Color.white, size: size, colorScheme: .light, scale: 1)?.width == 10)
    }

    @Test func `draws the views colour`() throws {
        let bitmap = try #require(renderBitmap(Color(red: 1, green: 0, blue: 0), size: size, colorScheme: .light))
        let expected = try #require(solid(width: 20, height: 10, rgba: [255, 0, 0, 255]))
        #expect(pixelDiff(bitmap, expected, tolerance: 2).differingFraction == 0)
    }

    @Test func `passes the colour scheme to the view`() throws {
        let bitmap = try #require(renderBitmap(SchemeSwatch(), size: size, colorScheme: .dark))
        let expected = try #require(solid(width: 20, height: 10, rgba: [0, 0, 0, 255]))
        #expect(pixelDiff(bitmap, expected, tolerance: 2).differingFraction == 0)
    }
}

/// Black in dark mode, white in light mode.
private struct SchemeSwatch: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        scheme == .dark ? Color.black : Color.white
    }
}
