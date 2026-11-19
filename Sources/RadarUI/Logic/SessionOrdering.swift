internal import Foundation

/// Urgency order for the session list: permission → waiting → working → idle (docs/design/components.md §5).
nonisolated func urgencyRank(_ status: SessionStatus) -> Int {
    switch status {
    case .permission: 0
    case .waiting: 1
    case .working: 2
    case .idle: 3
    }
}

/// Sorts by urgency. `sorted(by:)` is stable, so within a status the input order is kept
/// (callers pass oldest first).
nonisolated func sortedByUrgency(_ sessions: [SessionCardModel]) -> [SessionCardModel] {
    sessions.sorted { urgencyRank($0.status) < urgencyRank($1.status) }
}

/// "2 need you · 1 working · 3 idle"; zero groups are omitted; nothing at all reads "All quiet".
nonisolated func summaryLine(_ summary: StatusSummary) -> String {
    var parts: [String] = []
    if summary.needingYou > 0 {
        parts.append("\(summary.needingYou) \(needVerb(for: summary.needingYou)) you")
    }
    if summary.working > 0 {
        parts.append("\(summary.working) working")
    }
    if summary.idle > 0 {
        parts.append("\(summary.idle) idle")
    }
    return parts.isEmpty ? "All quiet" : parts.joined(separator: " · ")
}

/// What a submitted reply should send: trimmed, or `nil` when there's nothing to send.
nonisolated func normalisedReply(_ text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}

/// "1 needs you" but "2 need you".
nonisolated func needVerb(for count: Int) -> String {
    count == 1 ? "needs" : "need"
}
