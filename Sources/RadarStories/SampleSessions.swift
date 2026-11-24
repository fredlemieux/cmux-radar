public import RadarUI

/// Realistic, person-agnostic sample sessions for stories, playgrounds and snapshots.
public nonisolated enum SampleSessions {
    public static let waiting = SessionCardModel(
        id: "api-gateway",
        name: "api-gateway",
        location: "~/code/api-gateway",
        age: "3m",
        status: .waiting,
        summary: "Added rate limiting to the public routes. Load test passes at 2k rps; p99 went from 41 ms to 44 ms.",
        question: "Ship it behind a feature flag, enable it for everyone, or add per-tenant limits first?",
        replies: [
            ReplyOption(index: 1, label: "Feature flag"),
            ReplyOption(index: 2, label: "Everyone"),
            ReplyOption(index: 3, label: "Per-tenant first"),
        ],
    )

    public static let waitingNoReplies = SessionCardModel(
        id: "docs-site",
        name: "docs-site",
        location: "~/code/docs",
        age: "12m",
        status: .waiting,
        summary: "Rewrote the getting-started guide and fixed 14 broken links.",
        question: "Anything you want changed before I open the pull request?",
    )

    public static let waitingCantReply = SessionCardModel(
        id: "remote-box",
        name: "remote-box",
        location: "ssh: build-01",
        age: "6m",
        status: .waiting,
        summary: "Finished the dependency upgrade on the build host.",
        question: "Restart the build agents now?",
        canReply: false,
    )

    public static let permission = SessionCardModel(
        id: "billing-migration",
        name: "billing-migration",
        location: "~/code/billing",
        age: "1m",
        status: .permission,
        summary: "Ready to backfill invoice totals on staging.",
        permission: PermissionModel(command: "$ pnpm db:migrate --env staging", expiresIn: "1:48 left"),
    )

    public static let permissionExpired = SessionCardModel(
        id: "infra",
        name: "infra",
        location: "~/code/infra",
        age: "4m",
        status: .permission,
        permission: PermissionModel(command: "$ terraform apply -target=module.cache", expired: true),
    )

    public static let working = SessionCardModel(
        id: "mobile-app",
        name: "mobile-app",
        location: "~/code/mobile",
        age: "1:12",
        status: .working,
        summary: "Running the test suite: 42 of 58 passing so far.",
        progress: 0.72,
    )

    public static let idle = SessionCardModel(
        id: "data-pipeline",
        name: "data-pipeline",
        age: "2h",
        status: .idle,
        summary: "Updated the nightly export schedule",
    )

    public static let idleOld = SessionCardModel(
        id: "design-tokens",
        name: "design-tokens",
        age: "3d",
        status: .idle,
        summary: "Idle since Monday",
    )

    /// A typical mixed day. Within each status the order is oldest first, as the app passes it;
    /// the list sorts by urgency and keeps that order inside each group.
    public static let typical: [SessionCardModel] = [working, idleOld, waiting, permission, idle]

    /// Twelve sessions, to check scrolling and density.
    public static let many: [SessionCardModel] = typical + (1 ... 7).map { number in
        SessionCardModel(
            id: "service-\(number)",
            name: "service-\(number)",
            age: "\(60 - number * 8)m",
            status: .idle,
            summary: "Nothing new",
        )
    }

    public static let allWaiting: [SessionCardModel] = [waiting, waitingNoReplies, permission]
}
