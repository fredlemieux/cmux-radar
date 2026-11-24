/// What a snapshot assertion concluded.
public enum SnapshotVerdict: Equatable, Sendable {
    /// No reference existed, or recording was forced. The actual image becomes the reference.
    case recorded(RecordReason)
    case matched
    case mismatched(differingFraction: Double)

    public enum RecordReason: Equatable, Sendable {
        case missingReference
        case recordingForced
    }
}

/// Decides the outcome of a snapshot comparison.
///
/// - Parameters:
///   - precision: the minimum fraction of pixels that must match, from 0 to 1.
///   - tolerance: per-channel difference still treated as equal (absorbs anti-aliasing noise).
public func judgeSnapshot(
    reference: Bitmap?,
    actual: Bitmap,
    record: Bool,
    precision: Double,
    tolerance: UInt8,
) -> SnapshotVerdict {
    if record {
        return .recorded(.recordingForced)
    }
    guard let reference else {
        return .recorded(.missingReference)
    }
    let difference = pixelDiff(reference, actual, tolerance: tolerance).differingFraction
    // Compare the matching share, not `1 - precision`, which isn't exact in floating point.
    if 1 - difference >= precision {
        return .matched
    }
    return .mismatched(differingFraction: difference)
}
