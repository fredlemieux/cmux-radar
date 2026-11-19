public import SwiftUI

/// One session on the Radar scope: a glyph and a tag. Each status has its own glyph shape, not just
/// its own colour: a square for a question, a large disc for a permission request, a medium disc
/// while working, a small dim dot when idle. Sessions that need you blink unless motion is reduced.
public struct RadarBlip: View {
    let session: SessionCardModel
    let tagLeads: Bool

    @Environment(\.radarTheme) private var theme

    /// `tagLeads` puts the tag before the glyph (the scope does this on its right half).
    public init(_ session: SessionCardModel, tagLeads: Bool = false) {
        self.session = session
        self.tagLeads = tagLeads
    }

    public var body: some View {
        HStack(spacing: theme.metrics.space4) {
            if tagLeads {
                tag
            }
            glyph
                .shadow(color: color, radius: needsYou(session.status) ? 6 : 0)
                .phaseAnimator(blinks ? [1.0, 0.25] : [1.0]) { glyph, opacity in glyph.opacity(opacity) } animation: { _ in
                    .easeInOut(duration: theme.motion.pulseDuration / 2)
                }
            if !tagLeads {
                tag
            }
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(session.name), \(statusWord)")
    }

    private var tag: some View {
        Text(blipTag(for: session))
            .font(theme.type.caption.weight(needsYou(session.status) ? .bold : .regular))
            .foregroundStyle(needsYou(session.status) ? color : theme.color(\.textTertiary))
            .lineLimit(1)
            .padding(.horizontal, theme.metrics.space2)
            .background(theme.color(\.surfacePopover))
    }

    private var blinks: Bool {
        needsYou(session.status) && !theme.reduceMotion
    }

    private var color: Color {
        theme.status(session.status)
    }

    @ViewBuilder private var glyph: some View {
        switch session.status {
        case .waiting: Rectangle().fill(color).frame(width: 9, height: 9)
        case .permission: Circle().fill(color).frame(width: 10, height: 10)
        case .working: Circle().fill(color).frame(width: 8, height: 8)
        case .idle: Circle().fill(color).frame(width: 6, height: 6)
        }
    }

    private var statusWord: String {
        switch session.status {
        case .waiting: "has a question"
        case .permission: "needs permission"
        case .working: "working"
        case .idle: "idle"
        }
    }
}
