public import SwiftUI

/// A thin progress track in the working colour. `fraction` is clamped to 0…1.
public struct ProgressBar: View {
    let fraction: Double

    @Environment(\.radarTheme) private var theme

    public init(_ fraction: Double) {
        self.fraction = clampedFraction(fraction)
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(theme.color(\.borderSubtle))
                Capsule()
                    .fill(theme.status(.working))
                    .frame(width: proxy.size.width * fraction)
            }
        }
        .frame(height: theme.metrics.progressHeight)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue(progressAccessibilityValue(fraction))
    }
}
