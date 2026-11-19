import RadarStories
import RadarUI
import SwiftUI

/// One component: its playground (live controls) and every story, rendered live.
struct ComponentPage: View {
    let component: String?
    let appearance: PreviewAppearance
    let zoom: Double
    @ObservedObject var context: StoryContext

    var body: some View {
        if let component, let stories = Stories.byComponent().first(where: { $0.component == component })?.stories {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header(component, stories: stories)
                    if let playground = Playgrounds.named(component) {
                        PlaygroundSection(
                            playground: playground,
                            level: stories.first?.level ?? .atoms,
                            appearance: appearance,
                            zoom: zoom,
                            context: context,
                        )
                    }
                    StoriesSection(stories: stories, appearance: appearance, zoom: zoom, context: context)
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            ContentUnavailableView("Pick a component", systemImage: "square.grid.2x2", description: Text("Choose one from the sidebar."))
        }
    }

    private func header(_ component: String, stories: [Story]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stories.first?.level.title.uppercased() ?? "")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(component)
                .font(.largeTitle.weight(.semibold))
            Text("\(stories.count) stories · every story is also a snapshot test")
                .foregroundStyle(.secondary)
        }
    }
}

private struct StoriesSection: View {
    let stories: [Story]
    let appearance: PreviewAppearance
    let zoom: Double
    let context: StoryContext

    /// The widest card in the group, so no fixed-size card spills into the next grid column.
    private var cardWidth: CGFloat {
        storyCardWidth(widest: stories.map(\.size.width).max() ?? 0, appearance: appearance, zoom: zoom)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stories").font(.title3.weight(.semibold))
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: cardWidth), spacing: 20, alignment: .topLeading)],
                alignment: .leading,
                spacing: 20,
            ) {
                ForEach(stories) { story in
                    StoryCard(title: story.name, appearance: appearance, zoom: zoom, size: story.size) {
                        StoryCanvas(story, context: context.scoped(to: story.id))
                    }
                }
            }
        }
    }
}

private struct PlaygroundSection: View {
    let playground: Playground
    let level: StoryLevel
    let appearance: PreviewAppearance
    let zoom: Double
    let context: StoryContext

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Playground").font(.title3.weight(.semibold))
            Text(appearance == .both
                ? "Change the inputs on the right; the component updates live. Shown in dark; switch to Light to see it light."
                : "Change the inputs on the right; the component updates live.")
                .foregroundStyle(.secondary)
            playground.render(
                context.scoped(to: "\(level.rawValue)/\(playground.component)/Playground"),
                appearance == .light ? .light : .dark,
                zoom,
            )
        }
    }
}

/// A titled frame around one rendering, in one or both appearances.
struct StoryCard<Content: View>: View {
    let title: String
    let appearance: PreviewAppearance
    let zoom: Double
    let size: CGSize
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.callout.weight(.medium))
            HStack(alignment: .top, spacing: 12) {
                if appearance != .light {
                    framed(.dark)
                }
                if appearance != .dark {
                    framed(.light)
                }
            }
        }
    }

    private func framed(_ scheme: ColorScheme) -> some View {
        content()
            .environment(\.colorScheme, scheme)
            .scaleEffect(zoom, anchor: .topLeading)
            .frame(width: size.width * zoom, height: size.height * zoom, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.separator))
    }
}

/// Width of one story card: the story at `zoom`, twice plus the gap when shown side by side.
func storyCardWidth(widest: CGFloat, appearance: PreviewAppearance, zoom: Double) -> CGFloat {
    let single = widest * zoom
    return appearance == .both ? single * 2 + 12 : single
}
