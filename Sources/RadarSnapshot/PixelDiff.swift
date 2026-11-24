/// The result of comparing two bitmaps pixel by pixel.
public enum PixelDiff: Equatable, Sendable {
    case sizeMismatch
    case compared(differing: Int, total: Int)

    /// Fraction of pixels that differ, from 0 (identical) to 1. Size mismatches count as 1.
    public var differingFraction: Double {
        switch self {
        case .sizeMismatch:
            1
        case let .compared(differing, total):
            Double(differing) / Double(total)
        }
    }
}

/// Compares two bitmaps. A pixel differs when any channel differs by more than `tolerance`.
public func pixelDiff(_ lhs: Bitmap, _ rhs: Bitmap, tolerance: UInt8) -> PixelDiff {
    guard lhs.width == rhs.width, lhs.height == rhs.height else {
        return .sizeMismatch
    }
    var differing = 0
    for index in 0 ..< lhs.pixelCount where !channelsMatch(lhs.rgba(at: index), rhs.rgba(at: index), tolerance) {
        differing += 1
    }
    return .compared(differing: differing, total: lhs.pixelCount)
}

private func channelsMatch(_ lhs: ArraySlice<UInt8>, _ rhs: ArraySlice<UInt8>, _ tolerance: UInt8) -> Bool {
    zip(lhs, rhs).allSatisfy { lhsChannel, rhsChannel in
        let delta = lhsChannel > rhsChannel ? lhsChannel - rhsChannel : rhsChannel - lhsChannel
        return delta <= tolerance
    }
}
