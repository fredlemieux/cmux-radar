# 0003 — Random property-test seeds instead of a committed fixed seed

Status: accepted · 2026-11-19 · deviates from factory standard §3.8

## Context

The factory standard asks for property tests with a fixed CI seed, for reproducibility. The Swift library used here, PropertyBased, deliberately makes a committed fixed seed fail: its `.fixedSeed` trait always records an issue ("do not commit usages of this trait"). It also prints the seed of any failing run.

## Decision

- Property tests run with a fresh random seed each time.
- A failing run prints its seed. Reproduce locally by adding the library's fixed-seed trait with that seed, fix the bug, then remove the trait.
- SwiftLint rule `no_committed_fixed_seed` makes a committed fixed seed a lint error.

## Consequences

- Reproducibility, the goal of the standard, is preserved: every failure is replayable from its printed seed.
- Coverage improves over time, because each CI run explores new inputs.
- A property can fail on CI for an input no local run has hit. That is a real bug found, not flakiness; it is triaged like any other failure.
