public import SwiftUI

/// The Radar skin's scope: range rings, a crosshair, a rotating sweep and a blip per session.
/// A session's bearing is fixed by its id and its range by how much it needs you (closer = more
/// urgent), so blips stay put while their status changes. The sweep stops when motion is reduced.
public struct RadarScope: View {
    let sessions: [SessionCardModel]
    let diameter: CGFloat

    @Environment(\.radarTheme) private var theme
    @State private var sweepAngle = 0.0

    public init(_ sessions: [SessionCardModel], diameter: CGFloat = 280) {
        self.sessions = sessions
        self.diameter = diameter
    }

    public var body: some View {
        ZStack {
            rings
            sweep
            ForEach(sessions) { session in
                let leads = tagLeads(bearing: blipBearing(for: session.id))
                RadarBlip(session, tagLeads: leads)
                    // The blip's glyph, not its tag, marks the session's position.
                    .frame(width: 0, height: 0, alignment: leads ? .trailing : .leading)
                    .offset(offset(of: session))
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

    private var sweep: some View {
        Circle()
            .fill(AngularGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.8),
                    .init(color: theme.status(.working).opacity(0.32), location: 1),
                ],
                center: .center,
            ))
            .rotationEffect(.degrees(sweepAngle))
            .accessibilityHidden(true)
            .onAppear(perform: startSweep)
    }

    private func startSweep() {
        guard !theme.reduceMotion else {
            return
        }
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            sweepAngle = 360
        }
    }

    private func offset(of session: SessionCardModel) -> CGSize {
        blipOffset(bearing: blipBearing(for: session.id), range: blipRange(for: session.status), radius: diameter / 2)
    }
}
