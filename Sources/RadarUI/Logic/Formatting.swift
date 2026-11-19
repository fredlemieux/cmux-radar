// Pure display helpers used by components. Mutation-tested (they live outside `Components/`).

/// "99+" above 99; never negative.
public nonisolated func badgeText(for count: Int) -> String {
    if count > 99 {
        return "99+"
    }
    return String(max(count, 0))
}

/// Clamps to 0…1; NaN becomes 0.
public nonisolated func clampedFraction(_ value: Double) -> Double {
    guard value.isFinite else {
        return value > 0 ? 1 : 0
    }
    return min(max(value, 0), 1)
}

/// "NEEDS YOU · 2"
public nonisolated func sectionLabelText(title: String, count: Int) -> String {
    "\(title.uppercased()) · \(count)"
}
