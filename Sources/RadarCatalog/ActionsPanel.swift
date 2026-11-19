import RadarStories
import SwiftUI

/// Storybook's "Actions" addon: every tap or submit from any story, newest first.
struct ActionsPanel: View {
    @ObservedObject var context: StoryContext

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Actions", systemImage: "bolt.horizontal")
                    .font(.headline)
                Text("\(context.log.count)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
                Button("Clear") { context.clear() }
                    .disabled(context.log.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            Divider()
            if context.log.isEmpty {
                Text("Click a button, chip or field in any story; its action shows up here.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(context.log) { action in
                    HStack(spacing: 10) {
                        Text("#\(action.id)").foregroundStyle(.tertiary).monospacedDigit()
                        Text(action.name).fontWeight(.medium)
                        if let detail = action.detail {
                            Text("“\(detail)”").foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(action.story).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(.background)
    }
}
