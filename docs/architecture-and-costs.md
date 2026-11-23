# Architecture and running costs

Prices verified on 2026-11-19 from the vendors' own pages (linked). Amounts are in USD, as published.

## Components

```
┌──────────────── user's Mac ─────────────────────────────────────┐
│  cmux (socket, events, Feed, ~/.cmuxterm)                       │
│      ▲  │                                                       │
│      │  ▼                                                       │
│  cmux-radar.app  ── RadarCore · RadarUI · skins                 │
│      │                                                          │
│      └── `claude -p` (opt-in summaries, user's own plan)        │
└─────────────────────────────────────────────────────────────────┘
GitHub: repo, Actions CI (macOS + Linux runners), Releases
Apple: Developer ID signing + notarisation (for v1.0 distribution)
Homebrew: tap / cask (free)
```

There is no server, database, storage or bandwidth to pay for. The app runs entirely on the user's machine.

## Per-component costs

| Component | Price | Source |
|---|---|---|
| GitHub Actions, macOS standard runner | $0.062 / minute | [Actions runner pricing](https://docs.github.com/en/billing/reference/actions-runner-pricing) |
| GitHub Actions, Linux 2-core | $0.006 / minute | same |
| GitHub Free included compute (private repos) | $12 / month, as money not minutes ≈ 193 macOS minutes. Usage is **blocked** when exhausted unless a payment method is on file. | [Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions) |
| Standard runners on public repos | Free, and don't consume the $12 | same |
| Apple Developer Program | $99 / year | [developer.apple.com/programs](https://developer.apple.com/programs/) |
| Summaries via `claude -p` | Counted against the end user's own Claude plan; ~$0.0006 per summary on Haiku (measured, `docs/SPEC.md` §4.1) | measured |

## Forecast

Assumptions: ~8 min of macOS per PR CI run (lint + build + test), ~3 runs per PR, ~15 PRs/month while building v1; mutation ~10 min per run.

| Period | Repo visibility | CI | Apple | Total |
|---|---|---|---|---|
| Launch (now → v1.0) | public | free | $0 (not needed until signing) | **$0/month** |
| 12 months | public | free | $99/year | **≈ $8/month** |
| 36 months | public | free | $99/year | **≈ $8/month** |

The repo went public before v1.0, so CI never grows into a cost. A private repo would need ~360 macOS min/month ≈ $22, over the $12 allowance. There is no media storage or audience-driven delivery: releases are a single small DMG served by GitHub Releases at no cost.

## Cost controls already in place

- macOS mutation jobs (PR and nightly) skip private repos, so a private fork doesn't burn its allowance; run `make mutate-changed` locally there.
- CI runs on pull requests only, not on pushes to `main`.
- `cancel-in-progress` concurrency stops superseded runs.
- Secret scanning runs on Linux (10× cheaper).

## Billing alerts

- None needed while the repo is public. If it ever goes private, add a payment method with a **$10 Actions budget** and an alert at 75%.

## Long-term gotchas

- **cmux internals.** Text comes from undocumented files in `~/.cmuxterm` (`docs/SPEC.md` §9). A cmux update can break summaries without warning; the app degrades to status-only.
- **Unsandboxed distribution.** The socket and file access rule out the Mac App Store; distribution is Developer ID + notarisation + Homebrew, which needs the $99/year membership every year or new builds can't be notarised.
- **macOS runner image churn.** Snapshot references depend on the macOS major version's text rendering; a runner image upgrade can mean re-recording references.
- **Claude CLI flag drift.** `claude -p` flags are feature-detected; a removed flag disables summaries rather than crashing.
