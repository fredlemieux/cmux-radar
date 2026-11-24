public import SwiftUI

/// The Radar skin's scope: range rings, a crosshair, a rotating sweep and a blip per session.
/// A session's bearing is fixed by its id and its range by how much it needs you (closer = more
/// urgent), so blips stay put while their status changes. The sweep stops when motion is reduced.
public struct RadarScope: View {
    let sessions: [SessionCardModel]
    let diameter: CGFloat

    @Environment(\.radarTheme) private var theme

    public init(_ sessions: [SessionCardModel], diameter: CGFloat = 280) {
        self.sessions = sessions
        self.diameter = diameter
    }

    public var body: some View {
        ZStack {
            rings
            // Gone, not frozen, when motion is reduced: a still wedge would sit over blips and
            // dim them. Being its own view, it starts and stops live with the setting.
            if !theme.reduceMotion {
                Sweep(color: theme.status(.working))
            }
            ForEach(sessions) { session in
                let leads = tagLeads(bearing: blipBearing(for: session.id))
                RadarBlip(session, tagLeads: leads)
                    // The blip's glyph, not its tag, marks the session's position.
                    .frame(width: 0, height: 0, alignment: leads ? .trailing : .leading)
                    .offset(offset(of: session, tagLeads: leads))
                    // Callers draw over quiet sessions, so their tags stay readable.
                    .zIndex(session.status.needsAttention ? 1 : 0)
            }
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(theme.color(\.borderStrong)))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Radar, \(sessions.count) sessions")
    }

    private var rings: some View {
        ZStack {
            Circle().strokeBorder(theme.color(\.borderSubtle)).padding(diameter / 6)
            Circle().strokeBorder(theme.color(\.borderSubtle)).padding(diameter / 3)
            Rectangle().fill(theme.color(\.borderSubtle)).frame(height: theme.metrics.hairline)
            Rectangle().fill(theme.color(\.borderSubtle)).frame(width: theme.metrics.hairline)
        }
        .accessibilityHidden(true)
    }

    /// Shifted by half a glyph so the glyph's centre, not its edge, sits on the session's point.
    private func offset(of session: SessionCardModel, tagLeads: Bool) -> CGSize {
        let point = blipOffset(bearing: blipBearing(for: session.id), range: blipRange(for: session.status), radius: diameter / 2)
        let halfGlyph: CGFloat = 5
        return CGSize(width: point.width + (tagLeads ? halfGlyph : -halfGlyph), height: point.height)
    }
}

/// The rotating beam: a trailing glow that turns once every four seconds.
private struct Sweep: View {
    let color: Color
    @State private var angle = 0.0

    var body: some View {
        Circle()
            .fill(AngularGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.8),
                    .init(color: color.opacity(0.32), location: 1),
                ],
                center: .center,
            ))
            .rotationEffect(.degrees(angle))
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
    }
}
