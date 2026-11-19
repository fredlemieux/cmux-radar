/// Everything a session card shows, already formatted for display (docs/design/components.md §3).
public nonisolated struct SessionCardModel: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let location: String?
    public let age: String
    public let status: SessionStatus
    public let summary: String?
    public let question: String?
    public let replies: [ReplyOption]
    public let permission: PermissionModel?
    public let progress: Double?
    public let canReply: Bool

    public init(
        id: String,
        name: String,
        location: String? = nil,
        age: String,
        status: SessionStatus,
        summary: String? = nil,
        question: String? = nil,
        replies: [ReplyOption] = [],
        permission: PermissionModel? = nil,
        progress: Double? = nil,
        canReply: Bool = true,
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.age = age
        self.status = status
        self.summary = summary
        self.question = question
        self.replies = replies
        self.permission = permission
        self.progress = progress
        self.canReply = canReply
    }
}

/// A one-tap quick reply. `index` is what gets sent ("1"), `label` what's shown.
public nonisolated struct ReplyOption: Identifiable, Equatable, Sendable {
    public let index: Int
    public let label: String
    public let detail: String?

    public init(index: Int, label: String, detail: String? = nil) {
        self.index = index
        self.label = label
        self.detail = detail
    }

    public var id: Int {
        index
    }
}

/// A blocked tool call waiting for Allow / Always / Deny.
public nonisolated struct PermissionModel: Equatable, Sendable {
    public let command: String
    /// "1:48 left"; `nil` when there's no deadline. Expired requests set `expired`.
    public let expiresIn: String?
    public let expired: Bool

    public init(command: String, expiresIn: String? = nil, expired: Bool = false) {
        self.command = command
        self.expiresIn = expiresIn
        self.expired = expired
    }
}

/// Counts per status, for the header line and the menu bar icon.
public nonisolated struct StatusSummary: Equatable, Sendable {
    public let waiting: Int
    public let permission: Int
    public let working: Int
    public let idle: Int

    public init(waiting: Int = 0, permission: Int = 0, working: Int = 0, idle: Int = 0) {
        self.waiting = waiting
        self.permission = permission
        self.working = working
        self.idle = idle
    }

    public init(_ sessions: [SessionCardModel]) {
        self.init(
            waiting: sessions.count { $0.status == .waiting },
            permission: sessions.count { $0.status == .permission },
            working: sessions.count { $0.status == .working },
            idle: sessions.count { $0.status == .idle },
        )
    }

    /// Sessions that need the user: waiting plus permission.
    public var needingYou: Int {
        waiting + permission
    }
}
