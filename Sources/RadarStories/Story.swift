public import CoreGraphics
public import RadarUI
public import SwiftUI

/// Where a component sits in the design system (docs/design/components.md §4).
public nonisolated enum StoryLevel: String, CaseIterable, Sendable {
    case atoms
    case molecules
    case organisms
    case templates

    public var title: String {
        rawValue.capitalized
    }
}

/// One state of one component. The catalog shows it; the snapshot tests render it.
public nonisolated struct Story: Identifiable, Sendable, CustomStringConvertible {
    public let level: StoryLevel
    public let component: String
    public let name: String
    /// The whole canvas, including padding around the component.
    public let size: CGSize
    public let render: @MainActor @Sendable (StoryContext) -> AnyView
    /// True when the story contains AppKit-backed controls (text fields), which only the hosted
    /// snapshot renderer can draw.
    public let usesAppKitControls: Bool

    public init(
        _ level: StoryLevel,
        _ component: String,
        _ name: String,
        size: CGSize,
        usesAppKitControls: Bool = false,
        render: @escaping @MainActor @Sendable (StoryContext) -> some View,
    ) {
        self.usesAppKitControls = usesAppKitControls
        self.level = level
        self.component = component
        self.name = name
        self.size = size
        self.render = { context in AnyView(render(context)) }
    }

    public var id: String {
        "\(level.rawValue)/\(component)/\(name)"
    }

    /// File-friendly name used for snapshot references.
    public var snapshotName: String {
        "\(level.rawValue)-\(component)-\(name)"
    }

    /// Shown as the test-case name in parameterised snapshot tests.
    public var description: String {
        "\(component) · \(name)"
    }
}

/// Every story in the design system, in catalog order.
public nonisolated enum Stories {
    public static let all: [Story] = atoms + molecules + organisms + templates

    /// Stories grouped by component, preserving order.
    public static func byComponent(_ stories: [Story] = all) -> [(component: String, stories: [Story])] {
        var order: [String] = []
        var groups: [String: [Story]] = [:]
        for story in stories {
            if groups[story.component] == nil {
                order.append(story.component)
            }
            groups[story.component, default: []].append(story)
        }
        return order.map { ($0, groups[$0] ?? []) }
    }
}

/// The surface a story is drawn on: the popover background, themed, with the component centred.
public struct StoryCanvas: View {
    let story: Story
    let theme: Theme
    let context: StoryContext

    public init(_ story: Story, theme: Theme = .classic, context: StoryContext = .silent) {
        self.story = story
        self.theme = theme
        self.context = context
    }

    public var body: some View {
        StoryBackground {
            story.render(context)
        }
        .frame(width: story.size.width, height: story.size.height)
        .radarTheme(theme)
    }
}

private struct StoryBackground<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.radarTheme) private var theme

    var body: some View {
        ZStack {
            theme.color(\.surfacePopover)
            content.padding(16)
        }
    }
}
