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
    precision: Double = 0.9995,
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
    let referenceData = FileManager.default.contents(atPath: paths.reference)
    let reference = referenceData.flatMap(PNGCodec.decode)
    if referenceData != nil, reference == nil, !record {
        // Never overwrite a reference we can't read (corrupt file, LFS pointer, conflict markers).
        let wrote = write(actual, to: paths.failure, creating: paths.directory)
        let actualNote = wrote ? "Actual: \(paths.failure)" : "Could not write the actual image."
        Issue.record("Reference at \(paths.reference) is not a readable PNG. \(actualNote)", sourceLocation: sourceLocation)
        return
    }
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
        guard write(actual, to: paths.reference, creating: paths.directory) else {
            Issue.record("Could not write snapshot to \(paths.reference)", sourceLocation: sourceLocation)
            return
        }
        Issue.record("Recorded snapshot (\(reason)) at \(paths.reference). Re-run to verify.", sourceLocation: sourceLocation)
    case let .mismatched(fraction):
        let wrote = write(actual, to: paths.failure, creating: paths.directory)
        let percent = (fraction * 1000).rounded() / 10
        let actualNote = wrote ? "Actual: \(paths.failure)" : "Could not write the actual image."
        Issue.record("Snapshot differs by \(percent)% of pixels. \(actualNote)", sourceLocation: sourceLocation)
    }
}

/// Returns whether the PNG was written.
private func write(_ bitmap: Bitmap, to path: String, creating directory: String) -> Bool {
    guard let data = PNGCodec.encode(bitmap) else {
        return false
    }
    try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
    return FileManager.default.createFile(atPath: path, contents: data)
}
