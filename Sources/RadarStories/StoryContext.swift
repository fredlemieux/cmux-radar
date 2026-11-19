public import Combine

/// Something a story's component did: a tap, a submitted reply. Shown in the catalog's Actions panel.
public nonisolated struct StoryAction: Identifiable, Equatable, Sendable {
    public let id: Int
    public let story: String
    public let name: String
    public let detail: String?
}

/// Hands stories the closures their components call, and records every call.
/// Snapshot tests use `.silent`; the catalog uses one live root and a scoped child per story.
public final class StoryContext: ObservableObject {
    @Published public private(set) var log: [StoryAction] = []
    private let recording: Bool
    private let story: String
    private weak var root: StoryContext?
    private var nextID = 1

    public init(recording: Bool = true) {
        self.recording = recording
        story = ""
    }

    private init(root: StoryContext, story: String) {
        recording = root.recording
        self.story = story
        self.root = root
    }

    /// A context that records nothing.
    public static var silent: StoryContext {
        StoryContext(recording: false)
    }

    /// A child whose actions are logged, on this context, as coming from `storyID`.
    public func scoped(to storyID: String) -> StoryContext {
        StoryContext(root: root ?? self, story: storyID)
    }

    /// A closure that records `name` when called.
    public func action(_ name: String) -> () -> Void {
        { self.record(name, detail: nil) }
    }

    /// A closure that records `name` with the value it receives.
    public func action(_ name: String) -> (String) -> Void {
        { value in self.record(name, detail: value) }
    }

    public func clear() {
        (root ?? self).log.removeAll()
    }

    private func record(_ name: String, detail: String?) {
        guard recording else {
            return
        }
        (root ?? self).append(story: story, name: name, detail: detail)
    }

    private func append(story: String, name: String, detail: String?) {
        log.insert(StoryAction(id: nextID, story: story, name: name, detail: detail), at: 0)
        nextID += 1
    }
}
