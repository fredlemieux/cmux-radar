/// Where a snapshot's reference and failure images live on disk.
public struct SnapshotPaths: Equatable, Sendable {
    public let directory: String
    public let reference: String
    public let failure: String
}

/// Reference images sit next to the test file:
/// `<test dir>/__Snapshots__/<test file stem>/<name>.png`.
/// A failed comparison writes `<name>.failure.png` beside it (git-ignored).
public func snapshotPaths(testFile: String, name: String) -> SnapshotPaths {
    let components = testFile.split(separator: "/", omittingEmptySubsequences: false)
    let fileName = components.last.map(String.init) ?? testFile
    let testDirectory = components.dropLast().joined(separator: "/")
    let stem = fileName.split(separator: ".").first.map(String.init) ?? fileName
    let directory = "\(testDirectory)/__Snapshots__/\(stem)"
    let safeName = sanitize(name)
    return SnapshotPaths(
        directory: directory,
        reference: "\(directory)/\(safeName).png",
        failure: "\(directory)/\(safeName).failure.png",
    )
}

/// Keeps letters, digits, `.`, `_` and `-`; everything else becomes `-`.
public func sanitize(_ name: String) -> String {
    String(name.map(safeCharacter))
}

private func safeCharacter(_ character: Character) -> Character {
    let allowed = character.isASCII && (character.isLetter || character.isNumber || "._-".contains(character))
    if allowed {
        return character
    }
    return "-"
}
