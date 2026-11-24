# cmux-radar v1 spec

Status: draft for review. Nothing here is implemented yet.

## 1. Goal

One place to see every agent session running in cmux, understand what each one is doing or asking, and answer it without switching to its tab.

### v1 scope

- Menu bar popover (Classic skin, default) with a card per session
- `⌥Space` inbox panel (two-pane, keyboard-first)
- Radar skin for the popover
- Answer types: free-text reply, permission (Once / Always / Deny), multiple-choice question, plan approval
- Jump to the session's cmux tab

### Out of scope for v1

- cmux sidebar extension (M5, after the core is stable)
- Skinning the inbox panel and sidebar
- LLM summaries (opt-in, M4)
- Agents other than Claude Code. The data model is agent-agnostic, but v1 is only tested against Claude Code. Codex comes next because cmux already bridges it.

## 2. What cmux gives us

Everything below was verified against **cmux 0.64.22** (`cmux capabilities`, `cmux events`, `cmux rpc`). Socket methods are called via `cmux rpc <method> <json>` or directly over the Unix socket (`$CMUX_SOCKET_PATH`).

| Need | Source | Notes |
|---|---|---|
| Live activity | `events.stream` / `cmux events --category agent --category feed --category notification` | NDJSON frames with `seq`, `name`, `workspace_id`, `surface_id`, `payload`. Resumable via `--after <seq>` / cursor file. Replay buffer 4,096 events; `ack.resume.gap` signals a gap. |
| Agent lifecycle | `agent.hook.<HookEventName>` events | e.g. `agent.hook.Stop`, `agent.hook.UserPromptSubmit`, `agent.hook.SessionEnd`. Payload has `session_id` (`claude-<uuid>`), `cwd`, `surface_id` (sometimes `null`), `phase` (`received`/`completed`). **Text fields are redacted**; only lengths are included. |
| Pending decisions | `feed.list { pending_only }`, `feed.item.received` / `feed.item.completed` events | Each item has `id`, `kind`, `status`, `workstream_id` (the session id), `cwd`, `created_at`, and, by kind, `request_id`, `tool_name`, `tool_input` (JSON string), `question_prompt`, `question_options` (`id`, `label`, `description`), `questions`, `text`. So the question and command text comes from `feed.list`, not from `workstream.jsonl`. `request_id` embeds the session id and a millisecond timestamp, so it is unique across sessions. Item kinds seen: `permissionRequest`, `question`, `exitPlan`, `stop`, `userPrompt`, `toolUse`, `toolResult`, `sessionStart`, `sessionEnd`. |
| Answering decisions | `feed.permission.reply { request_id, mode }` with mode `once`/`always`/`all`/`bypass`/`deny` (no deny message); `feed.question.reply { request_id, selections: [String] }`; `feed.exit_plan.reply { request_id, mode, feedback? }` with mode `ultraplan`/`bypassPermissions`/`autoAccept`/`manual`/`deny` | Verified in cmux source. Feed holds the agent's hook for up to **120 s**; after that the agent falls back to its own in-terminal prompt. |
| Notifications | `notification.list` | Gives title, subtitle, body, read state, workspace, surface and tab title (the tab title is what we display as the session name). |
| Terminal I/O | `surface.read_text`, `surface.send_text`, `surface.send_key` | `send_text` pastes without submitting; follow with `send_key enter`. |
| Jump | `feed.jump`, or focus via `focus-panel` / `open --surface` | |
| Last reply text | `~/.cmuxterm/workstream.jsonl` (Feed audit log), `~/.cmuxterm/claude-hook-sessions.json` | Contain `toolInputJSON`, question options, `assistantPreamble`, `lastUserMessage`, `lastBody`. **Undocumented internal files**; see Risks. |

### Design consequence

The socket gives us identity, timing and state but not the text. The text lives in Feed items and cmux's local state files. `RadarCore` therefore has two inputs: the **event stream** decides *when* something changed, and a **text resolver** fetches *what* it says.

## 3. Session model

```swift
struct Session: Identifiable, Equatable {
    let id: SessionID              // cmux workstream id, e.g. "claude-<uuid>"
    var agent: AgentKind           // .claude, .codex, .other(String)
    var title: String              // cmux tab title, falls back to cwd basename
    var cwd: String
    var workspaceID: String?
    var surfaceID: String?         // nil = can't type into it; jump only
    var state: SessionState
    var lastUserMessage: String?
    var lastAgentMessage: String?  // assistantPreamble / lastBody
    var summary: String?           // M4
    var pending: PendingDecision?
    var updatedAt: Date
}

enum SessionState { case working, waiting, needsPermission, needsAnswer, needsPlanApproval, idle, ended }

enum PendingDecision {
    case permission(requestID: String, tool: String, input: String)
    case question(requestID: String, questions: [Question])
    case plan(requestID: String, plan: String)
}
```

### State transitions (pure reducer)

| Event | New state |
|---|---|
| `agent.hook.UserPromptSubmit`, `agent.hook.PreToolUse`, `feed` `toolUse` | `working` |
| `feed.item.received` kind `permissionRequest` | `needsPermission` + `pending` |
| `feed.item.received` kind `question` | `needsAnswer` + `pending` |
| `feed.item.received` kind `exitPlan` | `needsPlanApproval` + `pending` |
| `feed.item.resolved` / `feed.item.completed` for the pending `request_id` | back to `working`, `pending = nil` |
| `agent.hook.Stop` (phase `completed`) | `waiting` |
| `notification.created` titled "Waiting" for a known surface | `waiting` (fallback when hooks are missing) |
| `waiting` with no activity for > 2 h (configurable) | `idle` |
| `agent.hook.SessionEnd` | `ended`; hidden after 10 min |
| Pending item older than 120 s with no resolution | state stays, card shows "answer in terminal" and offers Jump |

`reduce(state, event) -> state` is a pure function. Everything else is side effects around it.

In code (`Sources/RadarCore`): adapters decode cmux frames into `RadarEvent`s, and `reduce` applies them. Edge rules the table leaves open, because events can be late, replayed (bootstrap, resume gaps) or interleaved by parallel tools:

- **Stale events.** Order comes from the stream's `seq`, never the clock. Hooks, Feed and notifications stamp their times at different moments, and one source's clock can be skewed. An event from earlier in the stream than the last one applied to a session never changes it. So a replayed "Waiting" notification or a late Stop can't flip a newer turn to `waiting`, which would let Radar type mid-turn. Bootstrap snapshots carry the stream position they were read at, and a snapshot only changes a session if it's strictly newer than the last live event at that position. So a re-read "Waiting" notification can never undo a turn that started at the same position.
- **Context.** Later events fill in context the session lacked, such as a surface that was `null`. They never blank out known context, and never move a live session to a different surface or workspace: typing into the wrong tab is worse than not typing. A session resumed after it ended (a new prompt) takes the surface and workspace it resumed in.
- **Decisions.**
  - Resolution is keyed by `request_id` alone and closes only the decision holding that id.
  - A bootstrap `feed.list` closes any open decision Feed no longer holds (it was resolved during a resume gap).
  - A parallel tool call (`PreToolUse`, Feed `toolUse`) keeps an open decision open, because the agent is still blocked on it.
  - A re-sent copy of the open decision keeps its arrival time, so the Feed timeout isn't restarted.
  - `UserPromptSubmit`, `Stop` and `SessionEnd` drop any open decision, because its turn is over.
- **Unseen and ended sessions.**
  - A prompt, tool or decision event creates an unseen session.
  - A Stop for an unseen session is ignored (bootstrap discovers existing ones), so a late Stop never makes a ghost card.
  - Only a new prompt revives an ended session.
- **Feed replies** name the `request_id` shown on the card and are refused unless that decision is still the open one. They stop `replyMargin` (5 s) before the 120 s timeout, so a reply in flight still lands.
- `Session.pendingSince` records when the open decision arrived. Ageing (`.tick`) keeps `updatedAt`, because it is the last activity, not the last state change.

Known v1 limits:

- **One open decision per session.** If two subagents ask at once, the newer request replaces the older on the card, and the older can still be answered in the terminal via Jump.
- **A `working` session never ages.** If both Stop and the Waiting notification are missed, it stays working until the next event.
- **Event times are taken as stamped.** A source whose clock runs ahead delays idle, hide and the Feed expiry by the same amount. Ordering is unaffected because it uses `seq`. A fix is to stamp `pendingSince` with Radar's own receive time; this is tracked for the adapter PR.
- **A decision Feed dropped during a resume gap goes back to `working`.** It should instead stay visible as "answer in terminal"; this is tracked for the adapter PR.

### Bootstrap and resume

1. Read `claude-hook-sessions.json` → initial sessions (title, cwd, surface, last message).
2. `feed.list` → any decisions still pending.
3. `notification.list` → tab titles and unread waiting flags.
4. Subscribe to events from the persisted `seq` (`~/Library/Application Support/cmux-radar/events.seq`).
5. If `ack.resume.gap` is true, redo steps 1–3, then continue.
6. Persist `seq` only after the event has been reduced.

## 4. Actions

| Action | Allowed when | Implementation |
|---|---|---|
| `reply(text)` | `waiting` or `idle`, and `surfaceID != nil` | Re-check state right before sending. `surface.send_text` then `surface.send_key enter`. Never sends while `working` (the text would land mid-turn). |
| `allow(.once / .always)`, `deny` | `needsPermission`, pending not expired | `feed.permission.reply { request_id, mode }`. cmux takes no deny message, so `RadarAction.deny`'s `message` is dropped until it does. |
| `answer(optionIDs)` | `needsAnswer` | `feed.question.reply { request_id, selections }` |
| `approvePlan(mode)` / `rejectPlan(feedback)` | `needsPlanApproval` | `feed.exit_plan.reply { request_id, mode, feedback? }`; reject is mode `deny` |
| `jump()` | always | `feed.jump { workstream_id }` (the session id), else focus the surface |

Parameters verified against cmux source (0.64.22).

### Suggested replies (v1, no LLM)

When the last agent message ends in a numbered list (`1. …` / `2. …`), offer each item as a chip that sends its number. Otherwise offer nothing; no made-up suggestions.

### 4.1 Summaries via `claude -p` (M4)

No API key. Radar shells out to the `claude` CLI the user already has logged in:

```sh
claude -p --model haiku \
  --setting-sources "" \
  --tools "" \
  --no-session-persistence \
  --output-format json \
  "<prompt + last agent message>"
```

| Flag | Why |
|---|---|
| `--setting-sources ""` | Don't load user/project/local settings, so the user's own hooks don't fire for every summary. |
| `--tools ""` | Summarising needs no tools; removes any chance of side effects. |
| `--no-session-persistence` | Don't litter `~/.claude/projects` with one-off sessions. |
| `--output-format json` | Parse `.result`; log `.total_cost_usd` and `.duration_ms`. |
| `--model haiku` | Cheap and fast; configurable. |

Not `--bare`: it skips hooks too, but it only accepts `ANTHROPIC_API_KEY` auth (no OAuth or keychain), which defeats the point.

Run it from the app process, not from inside a cmux terminal. That way cmux's wrapper shim (which injects cmux's own hooks) isn't on `PATH`, and the summariser never shows up as a session in Radar.

Measured on Claude Code 2.1.321: ~1 s and ~$0.0006 per summary with Haiku. A test run with these flags produced no cmux events or Feed entries.

Rules:
- Trigger once per `Stop`, debounced, never while the popover is merely open.
- Cache by `(session_id, hash(last message))`.
- Concurrency limit 2; a 20 s timeout; on failure keep the heuristic first-line summary.
- Respects the user's plan quota; a settings toggle turns it off entirely.

## 5. Architecture

```
RadarCore (SwiftPM library, no UI, fully unit-tested)
  CmuxSocket        Unix-socket client: request/response + event stream
  CmuxStateReader   adapter over ~/.cmuxterm files (tail-reads, never loads whole files)
  Reducer           pure (SessionStore.State, Event) -> State
  SessionStore      @Observable; owns state, persists seq
  Actions           reply / allow / deny / answer / plan / jump
  Hotkeys           ⌘1–9 answer · ⇥ next session · ⌥⏎ jump · ⌥Space inbox

RadarUI (SwiftPM library)
  ReplyField, PermissionBar, QuestionOptions, StatusToken, SessionCardModel

Skins (SwiftPM library)
  ClassicSkin, RadarSkin

RadarApp (Xcode app target, MenuBarExtra, LSUIElement)
```

`workstream.jsonl` grows large (74 MB on the dev machine), so `CmuxStateReader` must tail from a stored byte offset, never read it in full.

### Skin contract

```swift
protocol Skin {
    static var id: String { get }
    static var displayName: String { get }
    associatedtype Popover: View
    @ViewBuilder func popover(sessions: [SessionCardModel], actions: SessionActions) -> Popover
    func menuBarIcon(summary: StatusSummary) -> MenuBarIcon
}
```

Rules: skins receive view models and an `actions` handle only. They can't touch the socket, files or hotkeys. Shared components (`ReplyField`, `PermissionBar`) take a style, so skins restyle rather than rebuild them.

## 6. Privacy

- Everything is local. No network calls in v1.
- cmux marks its event stream as local-sensitive. Radar never forwards it.
- M4 summaries are opt-in and run through the user's existing `claude` CLI login (see §4.1), so there's no API key to manage. Only the last agent message is sent, never tool inputs.

## 7. Testing

Swift Testing, one behaviour per test, nested `@Suite`s per feature and scenario.

- **Reducer:** a test per transition row and edge rule in §3, with property tests over every state. Recorded, scrubbed event fixtures arrive with the cmux adapters that decode them.
- **Bootstrap:** gap handling, persisted `seq`, a missing `claude-hook-sessions.json`.
- **Actions:** reply refused while `working`; reply refused with `surfaceID == nil`; expired pending → jump only.
- **CmuxStateReader:** tail-reading from an offset; malformed lines skipped.
- **Skins:** snapshot per skin × state (waiting, permission, question, working, idle, empty, 12+ sessions).
- **Contract smoke test** (manual/CI-optional): run against a live cmux and assert the socket methods in §2 exist via `cmux capabilities`.

## 8. Milestones

| | Deliverable | Done when |
|---|---|---|
| M0 | SwiftPM skeleton, CI (build + test), SwiftLint | `swift test` green in CI |
| M1 | `RadarCore`: socket client, reducer, bootstrap, state reader | Reducer suite green; CLI debug dump prints live sessions |
| M2 | Menu bar app + Classic skin + actions | Can answer a real permission prompt and send a text reply from the popover |
| M3 | `⌥Space` inbox + Radar skin + skin switcher | Both skins pass snapshot suite |
| M4 | Opt-in summaries via `claude -p` (§4.1), settings, launch at login | Summary appears within ~2 s of `Stop`; summariser never appears as a session |
| M5 | cmux sidebar extension (CmuxExtensionKit) | |
| v1.0 | Signed + notarised build, Homebrew cask | |

## 9. Risks

| Risk | Mitigation |
|---|---|
| `~/.cmuxterm/*` formats are internal and may change | Isolate behind `CmuxStateReader`; check the cmux version at startup; degrade to socket-only (state without text) instead of crashing. Ask cmux upstream for a `feed.get` with payload. |
| `send_text` racing an agent that just started a turn | Re-check state immediately before sending; disable the reply box while `working`. |
| `surface_id` is sometimes `null` on hook events | Resolve it from `claude-hook-sessions.json` `activeSessionsBySurface`; otherwise jump only. |
| Feed's 120 s timeout | Show a countdown on decision cards; after expiry, offer Jump. |
| `claude` CLI flags change, or `claude` isn't on the app's `PATH` (GUI apps get a minimal `PATH`) | Resolve the binary via a login shell (`zsh -lc 'command -v claude'`) once and cache it; feature-detect flags with `claude --help`; fall back to heuristic summaries. |
| Socket access. cmux's default `automation.socketControlMode` is `cmuxOnly`, which only accepts processes started inside a cmux terminal (an ancestry check), so a menu bar app is refused. | Onboarding asks the user to pick **Automation mode** (same-user local clients, no ancestry check) or **Password mode** in cmux settings; the app detects the refusal and shows that instruction. Never edit the user's cmux settings for them. |
| Socket auth (`CMUX_SOCKET_PASSWORD`) | Read the same sources the cmux CLI does; show a clear settings error. |

## 10. Open questions

1. ~~Exact params for the feed replies.~~ Resolved: see §2.
2. ~~Does `feed.list` return the item payload?~~ Resolved: yes, see §2. `workstream.jsonl` is only needed for the last reply text.
3. Can the menu bar app run unsandboxed (needed for the Unix socket and `~/.cmuxterm`)? Mac App Store distribution would then be out; Homebrew + notarised DMG only.
4. Should Radar also offer itself as a cmux Dock control (`dock.json`) for users who don't want a menu bar icon?
5. ~~Are Feed `request_id`s unique across sessions?~~ Resolved: yes, they embed the session id and a timestamp.
6. Which events mark a permission or question as decided or expired? Hook telemetry arrives as `feed.item.received` then `feed.item.completed`; the decision items still need a live capture before the adapter maps them.

## Design references

Mockups for Classic, Inbox, Sidebar, icon states, and the Radar, Groovebox, Departures and Flyer skins are in [`docs/design/mockups/`](design/mockups/README.md).
