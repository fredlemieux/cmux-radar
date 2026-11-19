internal import CoreGraphics
internal import RadarUI
internal import SwiftUI

nonisolated extension Stories {
    /// docs/design/components.md §4, Atoms.
    static let atoms: [Story] = statusDot + countBadge + keyHint + iconButton + replyChip
        + actionButton + commandBlock + progressBar + sectionLabel + radarAtoms

    private static let small = CGSize(width: 120, height: 56)
    private static let medium = CGSize(width: 260, height: 64)
    private static let wide = CGSize(width: 380, height: 80)

    private static let statusDot: [Story] = [
        Story(.atoms, "StatusDot", "Waiting", size: small) { _ in StatusDot(.waiting) },
        Story(.atoms, "StatusDot", "Waiting pulsing", size: small) { _ in StatusDot(.waiting, pulsing: true) },
        Story(.atoms, "StatusDot", "Waiting pulsing, reduced motion", size: small) { _ in
            StatusDot(.waiting, pulsing: true).radarTheme(.classic, motion: .reduced)
        },
        Story(.atoms, "StatusDot", "Permission", size: small) { _ in StatusDot(.permission) },
        Story(.atoms, "StatusDot", "Working", size: small) { _ in StatusDot(.working) },
        Story(.atoms, "StatusDot", "Idle", size: small) { _ in StatusDot(.idle) },
    ]

    private static let countBadge: [Story] = [
        Story(.atoms, "CountBadge", "One", size: small) { _ in CountBadge(1) },
        Story(.atoms, "CountBadge", "Two", size: small) { _ in CountBadge(2) },
        Story(.atoms, "CountBadge", "Twelve", size: small) { _ in CountBadge(12) },
        Story(.atoms, "CountBadge", "Over ninety-nine", size: small) { _ in CountBadge(150) },
        Story(.atoms, "CountBadge", "Permission", size: small) { _ in CountBadge(1, attention: .permission) },
    ]

    private static let keyHint: [Story] = [
        Story(.atoms, "KeyHint", "Command 1", size: small) { _ in KeyHint("⌘1") },
        Story(.atoms, "KeyHint", "Option return", size: small) { _ in KeyHint("⌥⏎") },
        Story(.atoms, "KeyHint", "Tab", size: small) { _ in KeyHint("⇥") },
    ]

    private static let iconButton: [Story] = [
        Story(.atoms, "IconButton", "Search", size: small) { context in IconButton(
            "magnifyingglass",
            label: "Search sessions",
            action: context.action("search"),
        ) },
        Story(.atoms, "IconButton", "Settings", size: small) { context in IconButton(
            "gearshape",
            label: "Settings",
            action: context.action("settings"),
        ) },
        Story(.atoms, "IconButton", "Search disabled", size: small) { context in
            IconButton("magnifyingglass", label: "Search sessions", action: context.action("search")).disabled(true)
        },
        Story(.atoms, "IconButton", "Send", size: small) { context in IconButton(
            "arrow.right",
            label: "Send reply",
            style: .filled,
            action: context.action("send"),
        ) },
        Story(.atoms, "IconButton", "Send disabled", size: small) { context in
            IconButton("arrow.right", label: "Send reply", style: .filled, action: context.action("send")).disabled(true)
        },
    ]

    private static let replyChip: [Story] = [
        Story(.atoms, "ReplyChip", "Default", size: medium) { context in ReplyChip(
            index: 1,
            label: "Build it",
            action: context.action("pick 1"),
        ) },
        Story(.atoms, "ReplyChip", "Highlighted", size: medium) { context in ReplyChip(
            index: 2,
            label: "Try Muster",
            highlighted: true,
            action: context.action("pick 2"),
        ) },
        Story(.atoms, "ReplyChip", "Long label", size: medium) { context in
            ReplyChip(index: 3, label: "Fork Muster and add free-text replies through cmux", action: context.action("pick 3"))
        },
    ]

    private static let actionButton: [Story] = [
        Story(.atoms, "ActionButton", "Primary", size: medium) { context in ActionButton(
            "Allow once",
            style: .primary,
            action: context.action("allow once"),
        ) },
        Story(.atoms, "ActionButton", "Outline", size: medium) { context in ActionButton("Deny", action: context.action("deny")) },
        Story(.atoms, "ActionButton", "Disabled", size: medium) { context in
            ActionButton("Always", action: context.action("always")).disabled(true)
        },
    ]

    private static let commandBlock: [Story] = [
        Story(.atoms, "CommandBlock", "Short", size: wide) { _ in CommandBlock("$ bun Tools/myagora.ts --days 7") },
        Story(.atoms, "CommandBlock", "Long", size: CGSize(width: 380, height: 110)) { _ in
            CommandBlock(
                "$ rsync -avz --delete --exclude node_modules --exclude .build ./ deploy@example.internal:/srv/app/releases/2026-11-19",
            )
        },
    ]

    private static let progressBar: [Story] = [
        Story(.atoms, "ProgressBar", "Empty", size: medium) { _ in ProgressBar(0) },
        Story(.atoms, "ProgressBar", "Partial", size: medium) { _ in ProgressBar(0.42) },
        Story(.atoms, "ProgressBar", "Full", size: medium) { _ in ProgressBar(1) },
    ]

    private static let sectionLabel: [Story] = [
        Story(.atoms, "SectionLabel", "Needs you", size: medium) { _ in SectionLabel("Needs you", count: 2, status: .waiting) },
        Story(.atoms, "SectionLabel", "Working", size: medium) { _ in SectionLabel("Working", count: 1, status: .working) },
        Story(.atoms, "SectionLabel", "Idle", size: medium) { _ in SectionLabel("Idle", count: 3, status: .idle) },
    ]
}
