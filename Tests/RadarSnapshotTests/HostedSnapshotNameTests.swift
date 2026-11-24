// MUTATION-VERIFIED: killed 2/2 mutants on 2026-11-19 (RenderHosted.swift, hostedSnapshotName)
import CoreGraphics
import RadarSnapshot
import Testing

struct HostedSnapshotNameTests {
    @Test func `keeps the name on a retina display`() {
        #expect(hostedSnapshotName("card.dark", backingScale: 2) == "card.dark")
    }

    @Test func `suffixes the scale on a 1x display`() {
        #expect(hostedSnapshotName("card.dark", backingScale: 1) == "card.dark.1x")
    }

    @Test func `suffixes the scale on a 3x display`() {
        #expect(hostedSnapshotName("card.dark", backingScale: 3) == "card.dark.3x")
    }
}
