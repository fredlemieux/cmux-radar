public import SwiftUI

/// A session's status as a dot. Statuses that need attention get a soft ring and, when
/// `pulsing`, breathe (unless Reduce Motion is on).
public struct StatusDot: View {
    let status: SessionStatus
    let pulsing: Bool

    @Environment(\.radarTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    public init(_ status: SessionStatus, pulsing: Bool = false) {
        self.status = status
        self.pulsing = pulsing
    }

    public var body: some View {
        let color = theme.status(status)
        Circle()
            .fill(color)
            .frame(width: theme.metrics.dot, height: theme.metrics.dot)
            .background {
                if status.needsAttention {
                    Circle()
                        .fill(color.opacity(0.22))
                        .frame(width: theme.metrics.dot * 2, height: theme.metrics.dot * 2)
                        .scaleEffect(expanded ? 1.25 : 1)
                }
            }
            .frame(width: theme.metrics.dot * 2, height: theme.metrics.dot * 2)
            .onAppear(perform: startPulse)
            .accessibilityElement()
            .accessibilityLabel("Status")
            .accessibilityValue(status.accessibilityName)
    }

    private func startPulse() {
        guard pulsing, status.needsAttention, !reduceMotion else {
            return
        }
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            expanded = true
        }
    }
}
