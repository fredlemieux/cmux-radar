internal import CoreGraphics
internal import Foundation

/// Where on the scope a session's blip sits, in degrees clockwise from north. Stable for a
/// session id across launches (FNV-1a, not Swift's per-process `hashValue`), so blips don't jump.
nonisolated func blipBearing(for id: String) -> Double {
    var hash: UInt32 = 2_166_136_261
    for byte in id.utf8 {
        hash ^= UInt32(byte)
        hash = hash &* 16_777_619
    }
    return Double(hash % 3600) / 10
}

/// How far out a blip sits, as a fraction of the scope's radius: the more a session needs you,
/// the closer to the centre.
nonisolated func blipRange(for status: SessionStatus) -> Double {
    switch status {
    case .permission: 0.3
    case .waiting: 0.5
    case .working: 0.68
    case .idle: 0.86
    }
}

/// A blip's offset from the scope's centre (y grows downwards, as on screen).
nonisolated func blipOffset(bearing: Double, range: Double, radius: CGFloat) -> CGSize {
    let radians = bearing * .pi / 180
    let distance = Double(radius) * range
    return CGSize(width: sin(radians) * distance, height: -cos(radians) * distance)
}

/// Whether a blip's tag goes to the left of its glyph: on the scope's right half, so tags point
/// inwards and stay inside the circle.
nonisolated func tagLeads(bearing: Double) -> Bool {
    bearing < 180
}

/// The label beside a blip: the name in capitals (shortened to fit the scope) and what it's doing.
nonisolated func blipTag(for session: SessionCardModel) -> String {
    let name = tagName(session.name)
    switch session.status {
    case .waiting: return "\(name) ▲Q"
    case .permission: return "\(name) ▲PERM"
    case .working: return "\(name) ››\(progressSuffix(session.progress))"
    case .idle: return name
    }
}

/// The name in capitals, cut to 12 characters with an ellipsis so tags stay inside the scope.
/// The full name is in the contact panel and the blip's accessibility label.
nonisolated func tagName(_ name: String) -> String {
    let upper = name.uppercased()
    return upper.count > 12 ? upper.prefix(11) + "…" : upper
}

/// `" 72%"`, or nothing without progress.
nonisolated func progressSuffix(_ progress: Double?) -> String {
    progress.map { " \(Int((clampedFraction($0) * 100).rounded()))%" } ?? ""
}

/// The strip above the scope: how many sessions are calling in.
nonisolated func scopeHeadline(_ summary: StatusSummary) -> String {
    summary.needingYou > 0 ? "\(summary.needingYou) INBOUND" : "ALL CLEAR"
}

/// The session in the contact panel: the one selected while it still needs you, else the most
/// urgent one that does, else none.
public nonisolated func contact(selected: String?, in sessions: [SessionCardModel]) -> SessionCardModel? {
    let calling = contacts(in: sessions)
    for candidate in calling where candidate.id == selected {
        return candidate
    }
    return calling.first
}

/// The caller the panel stays on as sessions change: the current one while it still needs you,
/// else the most urgent. Pinning it means a newly urgent session never swaps in under a reply
/// being typed, and a caller that was answered never jumps back in later.
nonisolated func pinnedContact(_ current: String?, in sessions: [SessionCardModel]) -> String? {
    contact(selected: current, in: sessions)?.id
}

/// ⌘] moves to the next caller. Tab stays with the system, so every control remains reachable.
nonisolated func isNextContactKey(characters: String, command: Bool) -> Bool {
    command && characters == "]"
}

/// The next session that needs you after `current`, wrapping round (⇥ in the Radar skin).
nonisolated func nextContact(after current: String?, in sessions: [SessionCardModel]) -> String? {
    let ids = contacts(in: sessions).map(\.id)
    for (index, id) in ids.enumerated() where id == current {
        return ids[(index + 1) % ids.count]
    }
    return ids.first
}

/// Sessions that need you, most urgent first.
nonisolated func contacts(in sessions: [SessionCardModel]) -> [SessionCardModel] {
    sortedByUrgency(sessions).filter(\.status.needsAttention)
}
