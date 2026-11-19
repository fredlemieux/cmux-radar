/// How a status dot is drawn. Every status gets its own shape, so status reads without colour.
nonisolated enum DotTreatment: CaseIterable, Sendable {
    /// Filled dot with a soft halo: waiting for a reply.
    case halo
    /// Filled dot inside a stroked ring: blocked on permission.
    case ring
    /// Plain filled dot: working.
    case solid
    /// Outline only: idle.
    case hollow
}

nonisolated func dotTreatment(for status: SessionStatus) -> DotTreatment {
    switch status {
    case .waiting: .halo
    case .permission: .ring
    case .working: .solid
    case .idle: .hollow
    }
}

/// A dot pulses only when asked to, when its status needs attention, and never with Reduce Motion on.
nonisolated func shouldPulse(pulsing: Bool, status: SessionStatus, reduceMotion: Bool) -> Bool {
    pulsing && status.needsAttention && !reduceMotion
}

/// VoiceOver value for a progress bar: "72 percent".
nonisolated func progressAccessibilityValue(_ fraction: Double) -> String {
    "\(Int((clampedFraction(fraction) * 100).rounded())) percent"
}

/// Idle section labels use tertiary text; other statuses use their status colour.
nonisolated func sectionLabelUsesStatusColor(_ status: SessionStatus) -> Bool {
    status != .idle
}
