public import SwiftUI

/// A session's status as a dot. Each status has its own colour **and** shape (halo, ring, solid,
/// hollow), so it reads without colour vision. Attention statuses breathe when `pulsing`, unless
/// Reduce Motion is on; the pulse follows status and preference changes live.
public struct StatusDot: View {
    let status: SessionStatus
    let pulsing: Bool

    @Environment(\.radarTheme) private var theme

    public init(_ status: SessionStatus, pulsing: Bool = false) {
        self.status = status
        self.pulsing = pulsing
    }

    public var body: some View {
        let size = theme.metrics.dot
        ZStack {
            decoration
            core
        }
        .frame(width: size * 2, height: size * 2)
        .accessibilityElement()
        .accessibilityLabel("Status")
        .accessibilityValue(status.accessibilityName)
    }

    @ViewBuilder private var core: some View {
        let color = theme.status(status)
        let size = theme.metrics.dot
        switch dotTreatment(for: status) {
        case .hollow:
            Circle().strokeBorder(color, lineWidth: theme.metrics.dotRingWidth).frame(width: size, height: size)
        case .halo, .ring, .solid:
            Circle().fill(color).frame(width: size, height: size)
        }
    }

    @ViewBuilder private var decoration: some View {
        let color = theme.status(status)
        let size = theme.metrics.dot * 2
        switch dotTreatment(for: status) {
        case .halo:
            pulse(Circle().fill(color.opacity(theme.opacity.halo)).frame(width: size, height: size))
        case .ring:
            pulse(Circle().strokeBorder(color, lineWidth: theme.metrics.dotRingWidth).frame(width: size, height: size))
        case .solid, .hollow:
            EmptyView()
        }
    }

    /// Breathes between 1× and `motion.pulseScale`. `phaseAnimator` starts at 1×, so static renders
    /// (snapshots) are deterministic, and switching `shouldPulse` off stops it immediately.
    @ViewBuilder private func pulse(_ view: some View) -> some View {
        if shouldPulse(pulsing: pulsing, status: status, reduceMotion: theme.reduceMotion) {
            view.phaseAnimator([1, theme.motion.pulseScale]) { content, scale in
                content.scaleEffect(scale)
            } animation: { _ in
                .easeInOut(duration: theme.motion.pulseDuration)
            }
        } else {
            view
        }
    }
}
