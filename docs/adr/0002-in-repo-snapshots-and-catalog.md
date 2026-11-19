# 0002 — In-repo snapshot testing and component catalog

Status: accepted · 2026-11-19

## Context

The factory standards call for Storybook-style component development (every state viewable in isolation) and visual verification (Gate 0).

Options considered:

| Option | Why not |
|---|---|
| Point-Free swift-snapshot-testing | Imports XCTest unconditionally; fails to build with the Command Line Tools (ADR 0001). |
| Xcode Previews | Need Xcode. |
| eure/swift-storybook | Collects Xcode `#Preview`s at runtime; same Xcode dependency. |
| playbook-ios | Storybook-like and good, but unmaintained since 2024 and iOS-focused. |

## Decision

1. **`RadarSnapshot`** (≈300 lines): renders a SwiftUI view with `ImageRenderer`, normalises it to sRGB RGBA8, and compares it pixel by pixel with a committed PNG. Colour scheme is fixed per snapshot; light and dark are separate references. The pure parts (pixel diff, verdict, paths, PNG codec) are property-tested and mutation-tested at 100%. A missing reference is recorded **and fails the test**, so new snapshots are never accepted silently.
2. **`RadarCatalog`**: a small SwiftUI app (`make catalog`) listing every component and its stories, with live controls. Stories are plain values, so the same story list also drives snapshot tests: one source of truth for "every state of every component".

## Consequences

- Rendering tests depend on the macOS version's text rendering. References are recorded on the CI image's macOS major version, and the default precision (99.5% of pixels, per-channel tolerance 6) absorbs anti-aliasing noise.
- We own ≈300 lines of snapshot tooling plus the catalog, a trade we accept for zero Xcode dependency and stories that double as tests.

## Addendum (2026-11-19): two renderers

`ImageRenderer` draws AppKit-backed controls (`TextField`) as a yellow "unsupported" placeholder, which `TextFieldRenderingTests` pins. Stories that contain a text field set `usesAppKitControls` and are rendered by `renderHostedBitmap`: an `NSHostingView` in an offscreen window, captured with `cacheDisplay`.

Known artefact: offscreen capture (both `cacheDisplay` and `CALayer.render`) draws faint vertical lines just outside reply-chip capsules. Live window captures in dark and light mode show clean chips, so this is a capture artefact, not a component bug. Review hosted snapshots with that in mind; the `ImageRenderer` stories of the same components are the pixel-accurate reference.

## Addendum (2026-11-19): hosted references are keyed by display scale

The hosted renderer's window lays out on the main screen's backing grid. A 1× display (an external monitor, or a CI runner, which has no Retina screen) snaps glyphs and edges to whole points, so the 2× bitmap differs from one captured on a Retina display by a fraction of a pixel at every edge (0.8–10% of pixels; fills identical). No threshold separates that from a real change such as a status colour.

Within one scale the output is byte-identical across machines: the 1× images rendered on CI and on a development machine with a 1× display matched exactly. So hosted references are named per scale: `<name>.png` at 2×, `<name>.1x.png` at 1× (`hostedSnapshotName`). Each scale is compared strictly against its own reference; none is skipped or loosened.

Changing a hosted story means recording both scales. Record the one your display uses with `make test`; for the other, either switch displays or take the images CI recorded from the `snapshots` artifact of the failing run, review them, and commit them.
