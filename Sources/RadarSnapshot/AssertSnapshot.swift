public import CoreGraphics
internal import Foundation
public import SwiftUI
public import Testing

/// Snapshot settings read from the environment.
public enum SnapshotEnvironment {
    /// `RADAR_RECORD_SNAPSHOTS=1 make test` re-records every reference image.
    public static var recordAll: Bool {
        ProcessInfo.processInfo.environment["RADAR_RECORD_SNAPSHOTS"] == "1"
    }
}

/// Renders `view` and compares it with the reference image beside the test file.
///
/// A missing reference is written and the test fails, so a new snapshot is never silently
/// accepted: re-run to confirm. On mismatch the actual image is written as `<name>.failure.png`.
@MainActor
public func assertSnapshot(
    of view: some View,
    size: CGSize,
    named name: String,
    colorScheme: ColorScheme = .dark,
    precision: Double = 0.995,
    tolerance: UInt8 = 6,
    record: Bool = SnapshotEnvironment.recordAll,
    filePath: String = #filePath,
    sourceLocation: SourceLocation = #_sourceLocation,
) {
    let fullName = "\(name).\(colorScheme == .dark ? "dark" : "light")"
    let paths = snapshotPaths(testFile: filePath, name: fullName)
    guard let actual = renderBitmap(view, size: size, colorScheme: colorScheme) else {
        Issue.record("Could not render \(fullName)", sourceLocation: sourceLocation)
        return
    }
    let reference = FileManager.default.contents(atPath: paths.reference).flatMap(PNGCodec.decode)
    let verdict = judgeSnapshot(
        reference: reference,
        actual: actual,
        record: record,
        precision: precision,
        tolerance: tolerance,
    )
    report(verdict, actual: actual, paths: paths, sourceLocation: sourceLocation)
}

@MainActor
private func report(_ verdict: SnapshotVerdict, actual: Bitmap, paths: SnapshotPaths, sourceLocation: SourceLocation) {
    switch verdict {
    case .matched:
        try? FileManager.default.removeItem(atPath: paths.failure)
    case let .recorded(reason):
        write(actual, to: paths.reference, creating: paths.directory)
        Issue.record("Recorded snapshot (\(reason)) at \(paths.reference). Re-run to verify.", sourceLocation: sourceLocation)
    case let .mismatched(fraction):
        write(actual, to: paths.failure, creating: paths.directory)
        let percent = (fraction * 1000).rounded() / 10
        Issue.record("Snapshot differs by \(percent)% of pixels. Actual: \(paths.failure)", sourceLocation: sourceLocation)
    }
}

private func write(_ bitmap: Bitmap, to path: String, creating directory: String) {
    guard let data = PNGCodec.encode(bitmap) else {
        return
    }
    try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
    FileManager.default.createFile(atPath: path, contents: data)
}
