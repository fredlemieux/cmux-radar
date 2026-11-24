# 0001 — SwiftPM-only build that works without Xcode

Status: accepted · 2026-11-19

## Context

cmux-radar is a macOS app, and the usual route is an Xcode project. Contributors may only have the Command Line Tools (CLT) installed; full Xcode is a 10+ GB install that needs an Apple ID. CI runners have Xcode.

## Decision

- The whole project is one SwiftPM package (`Package.swift`). No `.xcodeproj` is committed.
- Every task goes through `make`, which works with either Xcode or the CLT.
- Two CLT gaps are bridged by scripts, and both are no-ops when Xcode is present:
  - `scripts/swift-test-flags.sh` adds the CLT's Swift Testing framework and interop library to the search and runtime paths. Without it, libraries that `import Testing` (PropertyBased, `RadarSnapshot`) fail to build or load.
  - `scripts/swiftlint.sh` points SwiftLint at the CLT copy of SourceKit.
- The app bundle (Info.plist, `LSUIElement`, signing) will be produced by a script around `swift build` when the app target lands, not by an Xcode project.

## Consequences

- No Xcode Previews. The component catalog (ADR 0002) replaces them.
- XCTest isn't available under the CLT, so XCTest-only libraries (e.g. Point-Free's swift-snapshot-testing) can't be used.
- Anyone with Xcode can still open `Package.swift` in Xcode and get previews and debugging for free.
