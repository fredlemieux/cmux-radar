public import SwiftUI

/// The Radar skin's menu bar popover: an inbound strip, the scope, and the contact panel for the
/// session calling in. ⇥ moves to the next caller, ⌘1–9 picks a quick reply, ⌥⏎ jumps to its tab.
/// It applies the Radar theme itself, so it looks the same wherever it's placed.
public struct RadarPopover: View {
    let sessions: [SessionCardModel]
    @Binding var drafts: [String: String]
    let actions: SessionActions
    let onOpenCmux: () -> Void
    let motion: MotionPreference

    /// `motion` follows Reduce Motion by default; stories force `.reduced` for stable snapshots.
    public init(
        sessions: [SessionCardModel],
        drafts: Binding<[String: String]>,
        actions: SessionActions,
        onOpenCmux: @escaping () -> Void = {},
        motion: MotionPreference = .system,
    ) {
        self.sessions = sessions
        _drafts = drafts
        self.actions = actions
        self.onOpenCmux = onOpenCmux
        self.motion = motion
    }

    public var body: some View {
        RadarPopoverBody(sessions: sessions, drafts: $drafts, actions: actions, onOpenCmux: onOpenCmux)
            .radarTheme(.radar, motion: motion)
    }
}

private struct RadarPopoverBody: View {
    let sessions: [SessionCardModel]
    @Binding var drafts: [String: String]
    let actions: SessionActions
    let onOpenCmux: () -> Void

    @Environment(\.radarTheme) private var theme
    @State private var selected: String?

    var body: some View {
        VStack(spacing: 0) {
            strip
            VStack(spacing: theme.metrics.space12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("AGENT CONTROL")
                        .font(theme.type.title)
                        .foregroundStyle(theme.color(\.textPrimary))
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text("\(sessions.count) TRACKED")
                        .font(theme.type.caption)
                        .foregroundStyle(theme.color(\.textTertiary))
                }
                RadarScope(sessions)
                RadarContact(callingIn, draft: draft, actions: actions)
                Spacer(minLength: 0)
                footer
            }
            .padding(theme.metrics.space16)
            .background(ScanLines(color: theme.status(.working)))
            .background(theme.color(\.surfacePopover))
            .overlay(Rectangle().strokeBorder(theme.color(\.borderSubtle)))
            .padding(theme.metrics.space12)
        }
        .frame(width: theme.metrics.popoverWidth)
        .background(theme.color(\.surfaceBase))
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.radiusPopover))
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(phases: .down, action: handle)
    }

    private var callingIn: SessionCardModel? {
        contact(selected: selected, in: sessions)
    }

    private var draft: Binding<String> {
        guard let callingIn else {
            return .constant("")
        }
        let key = draftKey(for: callingIn)
        return Binding(get: { drafts[key] ?? "" }, set: { drafts[key] = $0 })
    }

    private var strip: some View {
        let summary = StatusSummary(sessions)
        return HStack {
            Spacer()
            Text("◎ \(scopeHeadline(summary))")
                .font(theme.type.badge)
                .foregroundStyle(summary.needingYou > 0 ? theme.status(.waiting) : theme.color(\.textTertiary))
                .padding(.horizontal, theme.metrics.space8)
                .padding(.vertical, theme.metrics.space2)
                .overlay(Rectangle().strokeBorder(theme.color(\.borderStrong)))
        }
        .padding(.horizontal, theme.metrics.space16)
        .padding(.top, theme.metrics.space8)
    }

    private var footer: some View {
        HStack {
            Text("⇥ NEXT CONTACT")
            Spacer()
            Text("⌥⏎ VECTOR TO TAB")
            Spacer()
            Button("OPEN CMUX", action: onOpenCmux)
                .buttonStyle(.plain)
                .foregroundStyle(theme.color(\.textPrimary))
        }
        .font(theme.type.caption)
        .foregroundStyle(theme.color(\.textTertiary))
    }

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        if press.key == .tab {
            selected = nextContact(after: callingIn?.id, in: sessions)
            return .handled
        }
        let command = keyCommand(
            characters: press.characters,
            isReturn: press.key == .return,
            command: press.modifiers.contains(.command),
            option: press.modifiers.contains(.option),
        )
        guard let command, let routed = route(command, focused: callingIn?.id, in: sessions) else {
            return .ignored
        }
        switch routed {
        case let .pick(id, option): actions.pick(id, option)
        case let .jump(id): actions.jump(id)
        }
        return .handled
    }
}

/// Faint horizontal scan lines, like a CRT.
private struct ScanLines: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(color.opacity(0.045)))
                y += 3
            }
        }
        .accessibilityHidden(true)
    }
}
