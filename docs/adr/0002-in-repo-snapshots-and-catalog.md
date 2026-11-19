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

1. **`RadarSnapshot`** (≈200 lines): renders a SwiftUI view with `ImageRenderer`, normalises it to sRGB RGBA8, and compares it pixel by pixel with a committed PNG. Colour scheme is fixed per snapshot; light and dark are separate references. The pure parts (pixel diff, verdict, paths, PNG codec) are property-tested and mutation-tested at 100%. A missing reference is recorded **and fails the test**, so new snapshots are never accepted silently.
2. **`RadarCatalog`**: a small SwiftUI app (`make catalog`) listing every component and its stories, with live controls. Stories are plain values, so the same story list also drives snapshot tests: one source of truth for "every state of every component".

## Consequences

- Rendering tests depend on the macOS version's text rendering. References are recorded on the CI image's macOS major version, and the default precision (99.5% of pixels, per-channel tolerance 6) absorbs anti-aliasing noise.
- We own ~400 lines of tooling, a trade we accept for zero Xcode dependency and stories that double as tests.
