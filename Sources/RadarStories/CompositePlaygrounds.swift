internal import RadarUI
internal import SwiftUI

nonisolated extension Playgrounds {
    static let composites: [Playground] = [
        Playground("SessionCard") { context, scheme, zoom in SessionCardPlayground(context: context, scheme: scheme, zoom: zoom) },
        Playground("ClassicPopover") { context, scheme, zoom in
            PopoverPlayground(context: context, scheme: scheme, zoom: zoom, skin: .classic)
        },
        Playground("RadarPopover") { context, scheme, zoom in
            PopoverPlayground(context: context, scheme: scheme, zoom: zoom, skin: .radar)
        },
    ]
}

/// One card with every input editable.
private struct SessionCardPlayground: View {
    let context: StoryContext
    let scheme: ColorScheme
    let zoom: Double
    @State private var status = SessionStatus.waiting
    @State private var name = "api-gateway"
    @State private var summary = "Added rate limiting to the public routes."
    @State private var question = "Ship it behind a feature flag or enable it for everyone?"
    @State private var withReplies = true
    @State private var canReply = true
    @State private var expired = false
    @State private var progress = 0.42
    @State private var draft = ""

    var body: some View {
        PlaygroundLayout(scheme: scheme, zoom: zoom, previewSize: CGSize(width: 468, height: 320)) {
            SessionCard(model, draft: $draft, actions: .logging(to: context))
        } controls: {
            StatusPicker(title: "Status", status: $status)
            TextField("Name", text: $name)
            TextField("Summary", text: $summary, axis: .vertical).lineLimit(1 ... 3)
            if status == .waiting {
                TextField("Question", text: $question, axis: .vertical).lineLimit(1 ... 3)
                Toggle("Quick replies", isOn: $withReplies)
                Toggle("Can reply here", isOn: $canReply)
            }
            if status == .permission {
                Toggle("Timed out", isOn: $expired)
            }
            if status == .working {
                Slider(value: $progress, in: 0 ... 1) { Text("Progress") }
            }
        }
    }

    private var model: SessionCardModel {
        SessionCardModel(
            id: name,
            name: name,
            location: "~/code/\(name)",
            age: "3m",
            status: status,
            summary: summary.isEmpty ? nil : summary,
            question: status == .waiting ? question : nil,
            replies: withReplies ? [ReplyOption(index: 1, label: "Feature flag"), ReplyOption(index: 2, label: "Everyone")] : [],
            permission: status == .permission
                ? PermissionModel(command: "$ pnpm db:migrate --env staging", expiresIn: expired ? nil : "1:48 left", expired: expired)
                : nil,
            progress: status == .working ? progress : nil,
            canReply: canReply,
        )
    }
}

/// The whole popover, alive: answering a card changes it, as the real app will.
private struct PopoverPlayground: View {
    enum Skin {
        case classic
        case radar
    }

    enum Scenario: String, CaseIterable, Identifiable {
        case typical = "Typical day"
        case everythingWaiting = "Everything waiting"
        case many = "Twelve sessions"
        case empty = "All quiet"

        var id: String {
            rawValue
        }

        var sessions: [SessionCardModel] {
            switch self {
            case .typical: SampleSessions.typical
            case .everythingWaiting: SampleSessions.allWaiting
            case .many: SampleSessions.many
            case .empty: []
            }
        }
    }

    let context: StoryContext
    let scheme: ColorScheme
    let zoom: Double
    let skin: Skin
    @State private var scenario = Scenario.typical
    @State private var sessions = SampleSessions.typical
    @State private var drafts: [String: String] = [:]

    var body: some View {
        PlaygroundLayout(scheme: scheme, zoom: zoom, previewSize: CGSize(width: 492, height: 800)) {
            switch skin {
            case .classic:
                ClassicPopover(
                    sessions: sessions,
                    drafts: $drafts,
                    actions: liveActions,
                    onSearch: context.action("search"),
                    onSettings: context.action("settings"),
                    onOpenCmux: context.action("open cmux"),
                )
            case .radar:
                RadarPopover(sessions: sessions, drafts: $drafts, actions: liveActions, onOpenCmux: context.action("open cmux"))
            }
        } controls: {
            Picker("Scenario", selection: $scenario) {
                ForEach(Scenario.allCases) { Text($0.rawValue).tag($0) }
            }
            .onChange(of: scenario) { _, new in reset(to: new) }
            Button("Reset") { reset(to: scenario) }
            Text("Reply, pick a quick reply or allow: the card starts working. Deny: it goes idle.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Logs every action and moves the session along, like the app will once wired to cmux.
    private var liveActions: SessionActions {
        let log = SessionActions.logging(to: context)
        return SessionActions(
            reply: { id, text in log.reply(id, text); startWorking(id, on: "Working on: \(text)") },
            pick: { id, option in log.pick(id, option); startWorking(id, on: "Working on option \(option.index): \(option.label)") },
            allow: { id in log.allow(id); startWorking(id, on: "Permission granted, running the command") },
            always: { id in log.always(id); startWorking(id, on: "Always allowed, running the command") },
            deny: { id in log.deny(id); goIdle(id, summary: "Permission denied") },
            jump: { id in log.jump(id) },
        )
    }

    private func reset(to scenario: Scenario) {
        sessions = scenario.sessions
        drafts = [:]
    }

    private func startWorking(_ id: String, on summary: String) {
        // The container owns drafts: an answered question's draft is gone.
        sessions.filter { $0.id == id }.forEach { drafts[draftKey(for: $0)] = nil }
        replace(id) { SessionCardModel(
            id: $0.id,
            name: $0.name,
            location: $0.location,
            age: "0:01",
            status: .working,
            summary: summary,
            progress: 0.05,
        ) }
    }

    private func goIdle(_ id: String, summary: String) {
        replace(id) { SessionCardModel(id: $0.id, name: $0.name, location: $0.location, age: "now", status: .idle, summary: summary) }
    }

    private func replace(_ id: String, with transform: (SessionCardModel) -> SessionCardModel) {
        withAnimation(.snappy) {
            sessions = sessions.map { $0.id == id ? transform($0) : $0 }
        }
    }
}
