import Foundation
import RadarStories
import RadarUI
import SwiftUI

/// How stories are rendered on a component page.
enum PreviewAppearance: String, CaseIterable, Identifiable {
    case dark = "Dark"
    case light = "Light"
    case both = "Side by side"

    var id: String {
        rawValue
    }
}

struct CatalogView: View {
    @StateObject private var context = StoryContext()
    /// `make catalog COMPONENT=ClassicPopover` opens straight onto a component.
    @State private var selection: String? = initialComponent(
        requested: ProcessInfo.processInfo.environment["COMPONENT"],
        available: Stories.byComponent().map(\.component),
    )
    @State private var search = ""
    @State private var appearance = PreviewAppearance.dark
    @State private var zoom = 1.0

    var body: some View {
        NavigationSplitView {
            CatalogSidebar(selection: $selection, search: search)
                .searchable(text: $search, placement: .sidebar, prompt: "Components")
                .navigationSplitViewColumnWidth(min: 200, ideal: 230)
        } detail: {
            VStack(spacing: 0) {
                ComponentPage(component: selection, appearance: appearance, zoom: zoom, context: context)
                Divider()
                ActionsPanel(context: context)
                    .frame(height: 170)
            }
            .toolbar { toolbar }
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem {
            Picker("Appearance", selection: $appearance) {
                ForEach(PreviewAppearance.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .help("Preview appearance")
        }
        ToolbarItem {
            Picker("Zoom", selection: $zoom) {
                Text("1×").tag(1.0)
                Text("1.5×").tag(1.5)
                Text("2×").tag(2.0)
            }
            .pickerStyle(.segmented)
            .help("Zoom")
        }
    }
}

/// Levels → components, filtered by the search text.
struct CatalogSidebar: View {
    @Binding var selection: String?
    let search: String

    var body: some View {
        List(selection: $selection) {
            ForEach(StoryLevel.allCases, id: \.self) { level in
                let groups = Stories.byComponent(Stories.all.filter { $0.level == level && matches($0.component) })
                if !groups.isEmpty {
                    Section(level.title) {
                        ForEach(groups, id: \.component) { group in
                            Label(group.component, systemImage: icon(for: level))
                                .badge(group.stories.count)
                                .tag(group.component)
                        }
                    }
                }
            }
        }
    }

    private func matches(_ component: String) -> Bool {
        search.isEmpty || component.localizedCaseInsensitiveContains(search)
    }

    private func icon(for level: StoryLevel) -> String {
        switch level {
        case .atoms: "circle.dotted"
        case .molecules: "circle.grid.2x1"
        case .organisms: "square.grid.2x2"
        case .templates: "macwindow"
        }
    }
}

/// The component to open first: the requested one if it exists, otherwise the first.
/// An unknown name is reported on stderr instead of opening a blank page.
func initialComponent(requested: String?, available: [String]) -> String? {
    guard let requested, !requested.isEmpty else {
        return available.first
    }
    if available.contains(requested) {
        return requested
    }
    FileHandle.standardError.write(Data("Unknown COMPONENT '\(requested)'. Opening \(available.first ?? "nothing").\n".utf8))
    return available.first
}
