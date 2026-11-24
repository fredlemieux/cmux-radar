# Design system: Classic skin

The Classic skin, broken down into tokens and components. This is the contract the `RadarUI` PRs implement: every component, every state, and the stories that show them. Other skins (Radar, …) reuse the same component inventory and view models and swap the theme and layout.

Source: the v1 design canvas (Classic popover, Inbox panel, cmux sidebar, menu bar icon states).

## 1. Principles

1. **One glance, one action.** A waiting session shows the question and the answer controls without a click.
2. **Status by colour, shape and place.** Each status has a colour *and* its own dot shape: waiting = halo, permission = ring, working = solid, idle = hollow (`DotTreatmentTests`). Permission's ring and idle's outline stand out without colour. Waiting and working differ only by a soft halo, so they are also separated by **position and grouping**: urgent sessions always sort first and render as cards with the question visible.
3. **Native first.** System font (SF Pro / SF Mono), system materials where they help, standard keyboard behaviour. The mockups used Inter; the native build uses the system font.
4. **Display-ready inputs.** Components never format dates or compute status; they get strings and enums.

## 2. Tokens

Every value lives in `Theme`. Components read `Theme` from the environment; they never hard-code a colour or size.

### Colour

| Token | Dark | Light | Use |
|---|---|---|---|
| `surface.base` | `#0E0F13` | `#F4F4F6` | Behind the popover (catalog canvas only) |
| `surface.popover` | `#1C1D23` | `#FFFFFF` | Popover / panel background |
| `surface.card` | white 5% | black 3% | Session card |
| `surface.cardQuiet` | white 3% | black 2% | Working card |
| `surface.inset` | black 30% | black 5% | Question block, command block, input |
| `border.subtle` | white 9% | black 8% | Card and popover edges |
| `border.strong` | white 14% | black 14% | Chips, outline buttons, input |
| `text.primary` | `#F2F2F4` | `#111114` | Names, questions |
| `text.secondary` | `#C9C9D1` | `#3C3C43` | Summaries |
| `text.tertiary` | `#9A9AA5` | `#65656D` | Ages, paths, hints |
| `status.waiting` | `#F5A524` | `#9A6200` | Needs your reply |
| `status.permission` | `#FF7A59` | `#C8431F` | Needs permission |
| `status.working` | `#5B9DFF` | `#2F6FE0` | Agent is running |
| `status.idle` | `#74747F` | `#85858E` | Nothing to do |
| `onStatus.waiting` | `#1A1203` | `#FFFFFF` | Text on a waiting-coloured fill |
| `onStatus.permission` | `#1F0A04` | `#FFFFFF` | Text on a permission-coloured fill |
| `action.primary` / `onAction.primary` | `#ECECEF` / `#111114` | `#111114` / `#FFFFFF` | Allow once |

**Contrast rules (tested):**
- Text: every text token on `surface.popover`, every `onX` on its fill, and the highlighted chip's number on its tint meet WCAG AA 4.5:1. Hint text (`text.tertiary`) is ≥ 4.5:1 too, since it's small.
- Graphics: every status colour is ≥ 3:1 on the popover and on a card (WCAG 1.4.11).
- Count badges exist only in the two attention colours, the only fills with an on-colour.

### Type

| Token | Font | Size / weight |
|---|---|---|
| `title` | SF Pro | 15 / semibold |
| `sessionName` | SF Pro | 13 / semibold |
| `body` | SF Pro | 12.5 / regular, line height 1.5 |
| `question` | SF Pro | 13 / regular |
| `caption` | SF Pro | 11 / regular |
| `chip` | SF Pro | 12 / medium |
| `mono` | SF Mono | 12 / regular |
| `sectionLabel` | SF Pro | 11 / semibold, tracking +0.06em, uppercase |
| `badge` | SF Pro | 11 / bold, monospaced digits |
| `button` / `buttonPrimary` | SF Pro | 12.5 / regular · semibold |

### Space, radius, size, motion

| Token | Value |
|---|---|
| `space` | 2, 4, 6, 8, 10, 12, 16 |
| `radius.chip` | 14 (pill) |
| `radius.control` | 8 (buttons, inset blocks) |
| `radius.input` | 10 |
| `radius.card` | 12 |
| `radius.popover` | 16 |
| `size.dot` | 8 |
| `size.control` | 28 (chips, icon buttons, send) · 32 (permission buttons) · 38 (reply field) |
| `popover.width` | 436 |
| `motion.pulse` | waiting/permission dot ring: 1 → 1.25×, 1.2 s ease-in-out, repeats; starts and stops live with status and Reduce Motion |
| `opacity` | halo 0.22 · tint 0.14 · disabled 0.45 · attention border 0.38 |

## 3. View models (RadarUI inputs)

```swift
enum SessionStatus { case waiting, permission, working, idle }

struct SessionCardModel: Identifiable {
    let id: String
    let name: String            // "GENERAL ADMIN"
    let location: String?       // "~/.claude"
    let age: String             // "3m", "1:12", "2h"
    let status: SessionStatus
    let summary: String?        // "Researched menu-bar apps…"
    let question: String?       // waiting only
    let replies: [ReplyOption]  // quick replies, may be empty
    let permission: PermissionModel?
    let progress: Double?       // 0…1, working only
    let canReply: Bool          // false → reply field disabled, Jump offered
}

struct ReplyOption: Identifiable { let index: Int; let label: String; let detail: String? }  // id == index; unique per session
struct PermissionModel { let command: String; let expiresIn: String?; let expired: Bool }  // "1:48 left"
struct StatusSummary { let waiting: Int; let permission: Int; let working: Int; let idle: Int }
```

Actions reach organisms as one `SessionActions` value whose closures take the session id: `reply(id, text)`, `pick(id, option)`, `allow(id)`, `always(id)`, `deny(id)`, `jump(id)`. Molecules take plain closures (`onReply`, `onPick`, `onAllow`, `onAlways`, `onDeny`, `onJump`, `IdleRow.onOpen`).

**Reply drafts belong to the container**, keyed by `draftKey(for:)`: the session id plus the question it answers (`SessionList`/`ClassicPopover` take `drafts: Binding<[String: String]>`, `SessionCard` and `ReplyField` take a `Binding<String>`). A new question has a new key, so an old draft never appears under it; the container drops a draft once its reply is sent.

## 4. Component inventory

Atoms → molecules → organisms → templates. **Story** = one catalog entry and one snapshot test per colour scheme.

### Atoms

| Component | Inputs | Stories |
|---|---|---|
| `StatusDot` | status, pulsing | waiting · waiting pulsing · waiting pulsing (reduced motion) · permission · working · idle |
| `CountBadge` | count, attention (waiting / permission) | 1 · 2 · 12 · 99+ · permission |
| `KeyHint` | keys (`"⌘1"`) | ⌘1 · ⌥⏎ · ⇥ |
| `IconButton` | symbol, accessibility label | search · search disabled · settings · send (filled) · send disabled |
| `ReplyChip` | index, label, highlighted | default · highlighted · long label (truncates) |
| `ActionButton` | title, style (`primary`, `outline`) | primary · outline · disabled |
| `CommandBlock` | text | short · long (wraps, max 3 lines) |
| `ProgressBar` | fraction | 0 · 0.42 · 1 |
| `SectionLabel` | title, count, status | needs you · working · idle |

### Molecules

| Component | Built from | Stories |
|---|---|---|
| `SessionHeader` | StatusDot, name, location, age | each status · long name truncates · no location |
| `QuestionBlock` | question text | one line · multi-line |
| `ReplyChips` | ReplyChip × n | 3 options · 1 option · overflow wraps |
| `ReplyField` | text field, KeyHint, send IconButton | empty · typing · disabled (`canReply == false` shows "Jump to tab") |
| `PermissionBar` | CommandBlock, ActionButton × 3, optional countdown | default · with countdown · expired (buttons → Jump) |
| `IdleRow` | StatusDot, name, summary, age | default · long summary truncates |

### Organisms

| Component | Built from | Stories |
|---|---|---|
| `SessionCard` | SessionHeader + per-status body | waiting with replies · waiting no replies · waiting can't reply · permission · permission expiring · working · idle |
| `PopoverHeader` | title, StatusSummary line, IconButtons | mixed counts · all idle · empty |
| `PopoverFooter` | KeyHints, "Open cmux" link | default |
| `SessionList` | SessionCard × n, sorted: permission, waiting, working, idle | typical (6) · empty state · many (12+, scrolls) |
| `MenuBarIcon` | StatusSummary | idle · working · needs you (count) · permission |

### Templates

| Template | Stories |
|---|---|
| `ClassicPopover` | typical · empty ("All quiet") · everything waiting · light mode |
| `InboxPanel` *(later PR)* | session selected · nothing selected |
| `SidebarPanel` *(later PR)* | typical |

## 5. Behaviour rules the components own

- `SessionList` sorts by urgency: permission → waiting → working → idle. Within a group it keeps the input order; the app passes sessions oldest first. (The model carries a display age, not a timestamp, so the component can't sort by age itself.)
- `ReplyField` submits on ⏎, trims whitespace, ignores empty input, and clears after `onReply`.
- `ReplyChips` call `onPick`; they never type into the field.
- A card with `canReply == false` swaps the reply field for a "Jump to tab" button and hides its quick replies: you can always act, but never send to a session that can't take input.
- A permission card without request details still offers "Jump to tab".
- Long names and summaries truncate with an ellipsis; questions never truncate (they're the point).

## 6. Accessibility

- Every `IconButton` has an accessibility label. Status dots carry the status name as their accessibility value.
- Cards are accessibility containers labelled "‹name›, ‹status›".
- All actions are reachable by keyboard (implemented in `SessionList`, mapping tested in `KeyCommandTests`): ⇥ moves focus between cards (focused card gets a ring), ⌘1–9 sends that quick reply on the focused card (only when it can take a reply), ⌥⏎ jumps to its tab.
- Buttons whose titles show shortcut glyphs carry glyph-free accessibility labels.
- Reduce Motion disables the pulse.

## 7. Delivery order

| PR | Contents |
|---|---|
| `feat/ui-tokens` | `Theme` (dark + light) with contrast tests; all atoms with snapshot tests |
| `feat/catalog` | `RadarCatalog` app: story registry, sidebar, canvas, light/dark toggle, live controls; stories for every atom |
| `feat/ui-composites` | molecules, organisms, `ClassicPopover` template, their stories and snapshots |
| `feat/core-reducer` | `RadarCore` session model + reducer (independent of UI) |
| `feat/skin-radar` | Radar theme + layout over the same view models |
