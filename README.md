# cmux-radar

> See every AI coding agent running in [cmux](https://cmux.com) from your menu bar: which ones are working, which are waiting on you, and what they're asking. Answer without switching tabs.

**Status:** pre-alpha. Toolchain in place; components in progress.

---

## Why

cmux's notification menu tells you *that* an agent is waiting ("Claude is waiting for your input") but not *what* it wants. With six tabs open you end up clicking through each one to find out.

cmux-radar shows every agent session as a card with:

- **Status**: working, waiting on you, asking permission, idle
- **What happened**: a short summary of the last turn
- **The pending question**, in full, with one-tap suggested replies
- **A reply box** that types your answer straight into that agent's cmux tab, so you don't have to switch to it
- **Allow / Always / Deny** for permission prompts, inline

## Surfaces

| Surface | Trigger | Purpose |
|---|---|---|
| **Menu bar popover** | click the icon | Glanceable card stack. Answer the common case in one click. |
| **Inbox panel** | `⌥Space` | Keyboard-first, two-pane: sessions on the left, full context and reply on the right. |
| **cmux sidebar** | cmux right sidebar tab | Same cards inside cmux, built on cmux's sidebar extension support. |

## Skins

The presentation layer is swappable. All skins share the same data, keyboard shortcuts and reply behaviour. A skin only decides how things look.

| Skin | Status | Feel |
|---|---|---|
| **Classic** | v1 (default) | Calm, functional card stack |
| **Radar** | v1 | Phosphor scope. Sessions are blips; waiting ones flash amber; reply via a teletype panel |
| Groovebox | open for contribution | Sessions as lit sampler pads |
| Departures | open for contribution | Split-flap board; questions arrive as boarding passes |
| Flyer | open for contribution | Acid rave flyer; sessions as the lineup, answers as tear-off tabs |

Design mockups for all of these exist and will be linked here once the repo is public.

## Architecture

```
cmux  ──  events stream · list-notifications · read-screen · send / send-key · Feed
  │
RadarCore            Swift package, no UI
  ├─ CmuxClient      talks to the cmux socket / CLI
  ├─ SessionStore    live [Session] view models (status, summary, question, options)
  ├─ Actions         reply(), allow(), deny(), jump()
  ├─ Summariser      optional; short "what happened" lines from the transcript
  └─ Hotkeys         ⌘1–9 answer · ⇥ next · ⌥⏎ jump to tab · ⌥Space inbox
  │
RadarUI              shared building blocks: ReplyField, PermissionBar, StatusToken
  │
Skins                ClassicSkin · RadarSkin · …  (each one SwiftUI file implementing `Skin`)
  │
Apps                 menu bar app (MenuBarExtra) · cmux sidebar extension
```

### Design rules

1. **cmux is the source of truth.** Radar reads cmux's own events and notifications and doesn't install any hooks of its own. If cmux knows an agent is waiting, Radar knows too.
2. **Skins only draw.** Shortcuts, replies and permission decisions live in `RadarCore`, so a skin can't break answering.
3. **Replies go only to idle or waiting sessions.** The reply box is disabled while an agent is mid-turn, so text never lands in the middle of one.
4. **Local only.** Nothing leaves the machine except optional summaries, which are opt-in and use your own API key.

## Requirements

- macOS 14+
- cmux 0.64+ with agent hooks enabled (`cmux hooks setup`)

## Development

### Quick start

```sh
make bootstrap   # Homebrew tools (SwiftLint, SwiftFormat, lefthook) + git hooks
make check       # lint + build + test: what CI runs; run before every push
make catalog     # open the component catalog (the project's Storybook)
make help        # every task
```

Works with full Xcode or just the Command Line Tools (`xcode-select --install`); see [ADR 0001](docs/adr/0001-swiftpm-without-xcode.md).

### Layout

| Path | What |
|---|---|
| `Sources/RadarCore` | Pure domain logic: session model, reducer, actions. No UI, no I/O. |
| `Sources/RadarUI` | Presentational SwiftUI components. Display-ready inputs only. |
| `Sources/RadarCatalog` | Component catalog app: every component, every state, live controls. |
| `Sources/RadarSnapshot` | Snapshot testing without XCTest ([ADR 0002](docs/adr/0002-in-repo-snapshots-and-catalog.md)). |
| `Tests/*` | Swift Testing suites; snapshot references in `__Snapshots__/`. |

### Component catalog

`make catalog` opens **Radar Catalog**, the project's Storybook:

| Area | What it does |
|---|---|
| Sidebar | Components grouped as atoms → molecules → organisms → templates, with story counts and search |
| Playground | Live controls (text, toggles, pickers, sliders) for the component's inputs |
| Stories | Every named state, rendered live and clickable; Dark / Light / Side by side; 1×–2× zoom |
| Actions | Every tap or submit from any story, with the story it came from |

`make catalog COMPONENT=ClassicPopover` opens straight onto a component. The ClassicPopover playground is live: answer a card and it moves on, as the real app will.

Stories live in `Sources/RadarStories`. Adding one gives you a catalog entry **and** a snapshot test in both appearances: run `make test` once to record, review the PNG, run again.

### Quality gates

| Gate | How |
|---|---|
| Strict compiler | Swift 6 mode, warnings are errors, explicit imports |
| Lint + format | SwiftLint `--strict`, SwiftFormat; no force unwraps/casts/tries, no suppressions |
| Tests | Swift Testing, one behaviour per test, named as sentences |
| Property tests | PropertyBased, random seeds, failures print a replayable seed ([ADR 0003](docs/adr/0003-random-property-seeds.md)) |
| Mutation | Muter, ≥ 90% (`make mutate`, `make mutate-changed`) |
| Visual | Snapshot PNGs committed and reviewed; catalog checked before UI PRs |
| Commits | Conventional Commits via lefthook; stacked PRs |

### Troubleshooting

| Symptom | Fix |
|---|---|
| `no such module 'Testing'` or `lib_TestingInterop.dylib` not loaded | Use `make test`, not bare `swift test`; it adds the Command Line Tools paths. |
| SwiftLint: `Loading sourcekitdInProc.framework failed` | Use `make lint` (wraps SwiftLint with the CLT SourceKit path). |
| A snapshot test fails with "Recorded snapshot" | Expected on first run of a new snapshot: review the PNG, re-run. |
| A snapshot differs | Open `<name>.failure.png` next to the reference. If the change is intended: `make snapshots-record`. |
| lefthook says `core.hooksPath is set globally` | `make bootstrap` sets a repo-local hooks path; each hook still runs your global hook of the same name first. |

### Costs

No servers; the app is fully local. Ongoing costs are the Apple Developer Program ($99/year, for notarised releases) and CI minutes while the repo is private. Details and forecast: [architecture-and-costs](docs/architecture-and-costs.md).

## Docs

- [Spec](docs/SPEC.md)
- [Engineering standards](docs/standards.md)
- [Architecture and costs](docs/architecture-and-costs.md)
- [ADRs](docs/adr/)

## Roadmap

- [x] `RadarCore`: session model, reducer, action rules, suggested replies
- [ ] `RadarCore`: cmux client, state-file reader, session store
- [ ] Classic skin + menu bar app
- [ ] Inbox panel (`⌥Space`)
- [ ] Radar skin
- [ ] cmux sidebar extension
- [ ] Summaries (opt-in)
- [ ] Skin authoring guide + snapshot test harness
- [ ] Homebrew cask

## Contributing a skin

Coming with v1: implement the `Skin` protocol in a single SwiftUI file, add snapshot tests for each session state (waiting, permission, working, idle, empty, many), and open a PR.

## License

MIT
