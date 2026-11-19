internal import RadarUI
public import SwiftUI

/// A component with live controls, shown at the top of its catalog page (Storybook "Controls").
public nonisolated struct Playground: Sendable {
    public let component: String
    public let render: @MainActor @Sendable (StoryContext, ColorScheme, Double) -> AnyView

    public init(
        _ component: String,
        render: @escaping @MainActor @Sendable (StoryContext, ColorScheme, Double) -> some View,
    ) {
        self.component = component
        self.render = { context, scheme, zoom in AnyView(render(context, scheme, zoom)) }
    }
}

public nonisolated enum Playgrounds {
    public static let all: [Playground] = atoms

    public static func named(_ component: String) -> Playground? {
        all.first { $0.component == component }
    }
}

/// Preview on the left (themed, in the chosen appearance), controls on the right.
struct PlaygroundLayout<Preview: View, Controls: View>: View {
    let scheme: ColorScheme
    let zoom: Double
    var previewSize = CGSize(width: 420, height: 160)
    @ViewBuilder let preview: () -> Preview
    @ViewBuilder let controls: () -> Controls

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            PreviewSurface(content: preview)
                .frame(width: previewSize.width, height: previewSize.height)
                .radarTheme(.classic)
                .environment(\.colorScheme, scheme)
                .scaleEffect(zoom, anchor: .topLeading)
                .frame(width: previewSize.width * zoom, height: previewSize.height * zoom, alignment: .topLeading)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.separator))
            Form {
                controls()
            }
            .formStyle(.grouped)
            .frame(width: 320)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PreviewSurface<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @Environment(\.radarTheme) private var theme

    var body: some View {
        ZStack {
            theme.color(\.surfacePopover)
            content().padding(16)
        }
    }
}

/// A status picker used by several playgrounds.
struct StatusPicker: View {
    let title: String
    @Binding var status: SessionStatus

    var body: some View {
        Picker(title, selection: $status) {
            ForEach(SessionStatus.allCases, id: \.self) { Text($0.accessibilityName).tag($0) }
        }
    }
}
