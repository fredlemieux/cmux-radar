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

@MainActor
struct RenderHostedBitmapTests {
    let size = CGSize(width: 10, height: 5)

    @Test func `renders at twice the requested width`() {
        #expect(renderHostedBitmap(Color.white, size: size, colorScheme: .light)?.width == 20)
    }

    @Test func `renders at twice the requested height`() {
        #expect(renderHostedBitmap(Color.white, size: size, colorScheme: .light)?.height == 10)
    }

    @Test func `draws the views colour`() throws {
        let bitmap = try #require(renderHostedBitmap(Color(red: 1, green: 0, blue: 0), size: size, colorScheme: .light))
        let expected = try #require(solid(width: 20, height: 10, rgba: [255, 0, 0, 255]))
        #expect(pixelDiff(bitmap, expected, tolerance: 2).differingFraction == 0)
    }

    @Test func `passes the colour scheme to the view`() throws {
        let bitmap = try #require(renderHostedBitmap(SchemeSwatch(), size: size, colorScheme: .dark))
        let expected = try #require(solid(width: 20, height: 10, rgba: [0, 0, 0, 255]))
        #expect(pixelDiff(bitmap, expected, tolerance: 2).differingFraction == 0)
    }
}

/// Why the hosted renderer exists: `ImageRenderer` draws AppKit-backed controls as a yellow
/// "unsupported" placeholder. If Apple fixes that, the first test fails and the hosted renderer
/// can go (docs/adr/0002).
@MainActor
struct TextFieldRenderingTests {
    let size = CGSize(width: 160, height: 30)
    var field: some View {
        TextField("Reply", text: .constant("hello")).frame(width: 140)
    }

    @Test func `image renderer draws a placeholder instead of a text field`() throws {
        let bitmap = try #require(renderBitmap(field, size: size, colorScheme: .light))
        #expect(containsPlaceholderYellow(bitmap))
    }

    @Test func `hosted renderer draws the text field`() throws {
        let bitmap = try #require(renderHostedBitmap(field, size: size, colorScheme: .light))
        #expect(!containsPlaceholderYellow(bitmap))
    }
}

/// True when the bitmap has the saturated yellow SwiftUI uses for unsupported views.
private func containsPlaceholderYellow(_ bitmap: Bitmap) -> Bool {
    (0 ..< bitmap.pixelCount).contains { index in
        let pixel = Array(bitmap.rgba(at: index))
        return pixel[0] > 230 && pixel[1] > 180 && pixel[2] < 60
    }
}
