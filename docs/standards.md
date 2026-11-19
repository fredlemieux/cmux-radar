# Engineering standards (Swift edition)

This repo follows the software-factory engineering standards. The canonical standards are written for TypeScript; this file maps each one onto the Swift toolchain and records where Swift forces a different mechanism. Standards change by pull request, with the reason recorded.

## 1. Language and types

| Standard | Swift mechanism |
|---|---|
| Strict-plus compiler | Swift 6 language mode, complete concurrency checking, `treatAllWarnings(as: .error)`, upcoming features `ExistentialAny`, `InternalImportsByDefault`, `MemberImportVisibility` (`Package.swift`). |
| No escape hatches | SwiftLint errors: `force_unwrapping` (`!`), `force_cast` (`as!`), `force_try` (`try!`), `implicitly_unwrapped_optional`. `// swiftlint:disable` is itself a lint error (`no_swiftlint_disable`). Exceptions need repo-owner sign-off and an inline reason. |
| Untrusted data is `unknown` until validated | Decode cmux JSON into `Decodable` types at the boundary (`CmuxSocket`); never pass `[String: Any]` inward. |
| Exhaustive switches | Swift enforces exhaustive `switch` over enums. Avoid `default:` on our own enums so new cases fail to compile. |
| Explicit API surface | `InternalImportsByDefault`: a module re-exports a dependency only with `public import`. |

## 2. Architecture

| Standard | Swift mechanism |
|---|---|
| Pure core | `RadarCore`: no SwiftUI, no AppKit, no I/O. Clock and randomness are injected. |
| Dumb components | `RadarUI` takes display-ready values and closures. It does not depend on `RadarCore` (enforced by `Package.swift` target dependencies). |
| Thin containers | `RadarApp` (later) binds `RadarCore` to SwiftUI and cmux. Side effects live there only. |
| Monorepo / workspaces | One SwiftPM package, one target per layer. |

## 3. Testing: no test theatre

| Standard | Swift mechanism |
|---|---|
| Test framework | Swift Testing (`import Testing`), not XCTest. |
| One behaviour per test, `describe` / `it` | Nested types group scenarios (`struct WhenRecording`); each `@Test` checks one thing and uses a raw-identifier name that reads as a sentence: ``@Test func `rejects zero width`()``. SwiftFormat enforces the naming style. |
| Every test asserts | `#expect` / `#require` in every test; reviewed in the Uncle Bob loop. |
| No `.only` / `.skip` | `.disabled(` is a lint error (`no_disabled_tests`). |
| Mutation testing is the arbiter | Muter (`make mutate`, `make mutate-changed`). Threshold 90 for core and snapshot logic. Rendering and file-system glue is excluded and covered by example tests (`RenderTests`, `AssertSnapshotTests`). |
| Hybrid mutation gate | PR: changed files only. Nightly: full run. Both run on CI only while the repo is public (cost, see `architecture-and-costs.md`); while private, run `make mutate-changed` before pushing. |
| Property-based tests | `PropertyBased` (`propertyCheck`). **Seeds are random per run; failures print the seed** (ADR 0003). |
| Test-diary headers | First line of every test file: `// MUTATION-VERIFIED: killed X/Y mutants on <date>`. |
| Gate 0: look at it | Snapshot PNGs under `__Snapshots__/` are committed and reviewed in the PR diff. Every component also has catalog stories (`make catalog`), viewed before a UI PR is opened. |
| E2E fails hard | No `continue-on-error` in CI. |

## 4. Tooling

| Concern | Tool |
|---|---|
| Build / package manager | SwiftPM (Swift 6.2+). Works with Xcode or the Command Line Tools alone (ADR 0001). |
| Task runner | `make` (`make help`). |
| Lint | SwiftLint, `--strict` (`.swiftlint.yml`). |
| Format | SwiftFormat (`.swiftformat`), 140 columns. |
| Unit tests | Swift Testing. |
| Snapshot tests | `RadarSnapshot`, in-repo (ADR 0002). |
| Component catalog (Storybook) | `RadarCatalog` app, in-repo (ADR 0002). |
| Mutation | Muter. |
| Property-based tests | PropertyBased. |
| Git hooks | lefthook: format + lint on commit, Conventional Commits check, build + test on push. |
| Tool versions | `Brewfile` + `scripts/check-tool-versions.sh` (major.minor asserted). |

## 5. Supply chain and security

- SwiftPM dependencies pinned with `exact:` versions; `Package.resolved` committed.
- GitHub Actions pinned by full commit SHA with the version in a comment. No `pull_request_target`.
- gitleaks on every PR.
- The app makes no network calls of its own; see `docs/SPEC.md` §6.

## 6. Docs and process

Unchanged from the canonical standards: full README, person-agnostic docs, ADRs in `docs/adr/`, running costs in `docs/architecture-and-costs.md`, Conventional Commits with no AI attribution lines, stacked PRs, `make check` before every push.
