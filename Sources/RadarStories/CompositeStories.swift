internal import CoreGraphics
public import RadarUI
internal import SwiftUI

nonisolated extension Stories {
    /// docs/design/components.md §4, Molecules.
    static let molecules: [Story] = sessionHeader + questionBlock + replyChips + replyField + permissionBar + idleRow

    /// docs/design/components.md §4, Organisms.
    static let organisms: [Story] = sessionCard + popoverChrome + sessionList + menuBarIcon

    /// docs/design/components.md §4, Templates.
    static let templates: [Story] = classicPopover

    private static let row = CGSize(width: 436, height: 64)
    private static let cardWidth: CGFloat = 436

    private static let sessionHeader: [Story] = [
        Story(.molecules, "SessionHeader", "Waiting", size: row) { _ in
            SessionHeader(name: "api-gateway", location: "~/code/api-gateway", age: "3m", status: .waiting)
        },
        Story(.molecules, "SessionHeader", "Permission", size: row) { _ in
            SessionHeader(name: "billing-migration", age: "1m", status: .permission, badge: "Permission")
        },
        Story(.molecules, "SessionHeader", "Working", size: row) { _ in
            SessionHeader(name: "mobile-app", location: "~/code/mobile", age: "1:12", status: .working)
        },
        Story(.molecules, "SessionHeader", "Long name truncates", size: row) { _ in
            SessionHeader(name: "a-very-long-session-name-that-will-not-fit", location: "~/code/somewhere/deep", age: "9m", status: .idle)
        },
    ]

    private static let questionBlock: [Story] = [
        Story(.molecules, "QuestionBlock", "One line", size: CGSize(width: cardWidth, height: 80)) { _ in
            QuestionBlock("Restart the build agents now?")
        },
        Story(.molecules, "QuestionBlock", "Multi-line", size: CGSize(width: cardWidth, height: 110)) { _ in
            QuestionBlock("Ship it behind a feature flag, enable it for everyone, or add per-tenant limits first?")
        },
    ]

    private static let replyChips: [Story] = [
        Story(.molecules, "ReplyChips", "Three options", size: CGSize(width: cardWidth, height: 72)) { context in
            ReplyChips(SampleSessions.waiting.replies) { context.action("pick")("\($0.index) \($0.label)") }
        },
        Story(.molecules, "ReplyChips", "One option", size: CGSize(width: cardWidth, height: 72)) { context in
            ReplyChips([ReplyOption(index: 1, label: "Restart now")]) { context.action("pick")("\($0.index) \($0.label)") }
        },
        Story(.molecules, "ReplyChips", "Wraps", size: CGSize(width: 300, height: 104)) { context in
            ReplyChips(SampleSessions.waiting.replies + [ReplyOption(index: 4, label: "Ask the team")]) {
                context.action("pick")("\($0.index) \($0.label)")
            }
        },
    ]

    private static let replyField: [Story] = [
        Story(.molecules, "ReplyField", "Empty", size: CGSize(width: cardWidth, height: 72), usesAppKitControls: true) { context in
            StateHost("") { text in
                ReplyField(
                    placeholder: "Reply to api-gateway…",
                    text: text,
                    onReply: context.action("reply"),
                    onJump: context.action("jump"),
                )
            }
        },
        Story(.molecules, "ReplyField", "Typed", size: CGSize(width: cardWidth, height: 72), usesAppKitControls: true) { context in
            StateHost("Go with the feature flag") { text in
                ReplyField(
                    placeholder: "Reply to api-gateway…",
                    text: text,
                    onReply: context.action("reply"),
                    onJump: context.action("jump"),
                )
            }
        },
        Story(.molecules, "ReplyField", "Can't reply", size: CGSize(width: cardWidth, height: 72)) { context in
            ReplyField(
                placeholder: "Reply…",
                canReply: false,
                text: .constant(""),
                onReply: context.action("reply"),
                onJump: context.action("jump"),
            )
        },
    ]

    private static let permissionBar: [Story] = [
        Story(.molecules, "PermissionBar", "Default", size: CGSize(width: cardWidth, height: 112)) { context in
            permissionBar(PermissionModel(command: "$ pnpm db:migrate --env staging"), context)
        },
        Story(.molecules, "PermissionBar", "With countdown", size: CGSize(width: cardWidth, height: 132)) { context in
            permissionBar(PermissionModel(command: "$ pnpm db:migrate --env staging", expiresIn: "1:48 left"), context)
        },
        Story(.molecules, "PermissionBar", "Expired", size: CGSize(width: cardWidth, height: 136)) { context in
            permissionBar(PermissionModel(command: "$ terraform apply -target=module.cache", expired: true), context)
        },
    ]

    @MainActor
    private static func permissionBar(_ model: PermissionModel, _ context: StoryContext) -> PermissionBar {
        PermissionBar(
            model,
            onAllow: context.action("allow once"),
            onAlways: context.action("always"),
            onDeny: context.action("deny"),
            onJump: context.action("jump"),
        )
    }

    private static let idleRow: [Story] = [
        Story(.molecules, "IdleRow", "Default", size: row) { context in
            IdleRow(SampleSessions.idle, onOpen: context.action("jump"))
        },
        Story(.molecules, "IdleRow", "Long summary truncates", size: row) { context in
            IdleRow(
                SessionCardModel(
                    id: "x",
                    name: "data-pipeline",
                    age: "2h",
                    status: .idle,
                    summary: "Updated the nightly export schedule and backfilled three weeks of missing partitions",
                ),
                onOpen: context.action("jump"),
            )
        },
    ]

    private static let sessionCard: [Story] = [
        card("Waiting with replies", SampleSessions.waiting, height: 290),
        card("Waiting, no replies", SampleSessions.waitingNoReplies, height: 210),
        card("Waiting, can't reply", SampleSessions.waitingCantReply, height: 200),
        card("Permission", SampleSessions.permission, height: 210),
        card("Permission expired", SampleSessions.permissionExpired, height: 190),
        card("Working", SampleSessions.working, height: 120),
        card("Idle", SampleSessions.idle, height: 70),
    ]

    private static func card(_ name: String, _ session: SessionCardModel, height: CGFloat) -> Story {
        let hasField = session.status == .waiting && session.canReply
        return Story(
            .organisms,
            "SessionCard",
            name,
            size: CGSize(width: cardWidth + 32, height: height),
            usesAppKitControls: hasField,
        ) { context in
            StateHost("") { draft in SessionCard(session, draft: draft, actions: .logging(to: context)) }
        }
    }

    private static let popoverChrome: [Story] = [
        Story(.organisms, "PopoverHeader", "Mixed", size: CGSize(width: cardWidth + 32, height: 90)) { context in
            PopoverHeader(
                summary: StatusSummary(SampleSessions.typical),
                onSearch: context.action("search"),
                onSettings: context.action("settings"),
            )
        },
        Story(.organisms, "PopoverHeader", "All quiet", size: CGSize(width: cardWidth + 32, height: 90)) { context in
            PopoverHeader(summary: StatusSummary(), onSearch: context.action("search"), onSettings: context.action("settings"))
        },
        Story(.organisms, "PopoverHeader", "All idle", size: CGSize(width: cardWidth + 32, height: 90)) { context in
            PopoverHeader(summary: StatusSummary(idle: 4), onSearch: context.action("search"), onSettings: context.action("settings"))
        },
        Story(.organisms, "PopoverFooter", "Default", size: CGSize(width: cardWidth + 32, height: 72)) { context in
            PopoverFooter(onOpenCmux: context.action("open cmux"))
        },
    ]

    private static let sessionList: [Story] = [
        list("Typical", SampleSessions.typical, height: 700),
        list("Many, scrolls", SampleSessions.many, height: 520),
        Story(.organisms, "SessionList", "Empty", size: CGSize(width: cardWidth + 32, height: 200)) { context in
            SessionList([], drafts: .constant([:]), actions: .logging(to: context))
        },
    ]

    private static func list(_ name: String, _ sessions: [SessionCardModel], height: CGFloat) -> Story {
        Story(.organisms, "SessionList", name, size: CGSize(width: cardWidth + 32, height: height), usesAppKitControls: true) { context in
            StateHost([String: String]()) { drafts in
                SessionList(sessions, drafts: drafts, actions: .logging(to: context))
            }
        }
    }

    private static let menuBarIcon: [Story] = [
        Story(.organisms, "MenuBarIcon", "Idle", size: CGSize(width: 120, height: 56)) { _ in MenuBarIcon(StatusSummary(idle: 3)) },
        Story(.organisms, "MenuBarIcon", "Working", size: CGSize(width: 120, height: 56)) { _ in MenuBarIcon(StatusSummary(working: 1)) },
        Story(.organisms, "MenuBarIcon", "Needs you", size: CGSize(width: 120, height: 56)) { _ in
            MenuBarIcon(StatusSummary(waiting: 2, working: 1))
        },
        Story(.organisms, "MenuBarIcon", "Permission", size: CGSize(width: 120, height: 56)) { _ in
            MenuBarIcon(StatusSummary(waiting: 1, permission: 1))
        },
    ]

    private static let classicPopover: [Story] = [
        popover("Typical", SampleSessions.typical, height: 760),
        popover("Everything waiting", SampleSessions.allWaiting, height: 780),
        popover("All quiet", [], height: 330),
    ]

    private static func popover(_ name: String, _ sessions: [SessionCardModel], height: CGFloat) -> Story {
        let hasField = sessions.contains { $0.status == .waiting && $0.canReply }
        return Story(
            .templates,
            "ClassicPopover",
            name,
            size: CGSize(width: cardWidth + 32, height: height),
            usesAppKitControls: hasField,
        ) { context in
            StateHost([String: String]()) { drafts in
                ClassicPopover(
                    sessions: sessions,
                    drafts: drafts,
                    actions: .logging(to: context),
                    onSearch: context.action("search"),
                    onSettings: context.action("settings"),
                    onOpenCmux: context.action("open cmux"),
                )
            }
        }
    }
}

@MainActor
public extension SessionActions {
    /// Records every card action in the catalog's Actions panel.
    static func logging(to context: StoryContext) -> SessionActions {
        let reply: (String) -> Void = context.action("reply")
        let pick: (String) -> Void = context.action("pick")
        let allow: (String) -> Void = context.action("allow once")
        let always: (String) -> Void = context.action("always")
        let deny: (String) -> Void = context.action("deny")
        let jump: (String) -> Void = context.action("jump")
        return SessionActions(
            reply: { id, text in reply("\(id): \(text)") },
            pick: { id, option in pick("\(id): \(option.index) \(option.label)") },
            allow: allow,
            always: always,
            deny: deny,
            jump: jump,
        )
    }
}
