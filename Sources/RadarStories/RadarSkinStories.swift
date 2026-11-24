internal import CoreGraphics
internal import RadarUI
internal import SwiftUI

/// The Radar skin's components, drawn in the Radar theme (docs/design/components.md §4).
nonisolated extension Stories {
    static let radarAtoms: [Story] = [
        blip("Question", SampleSessions.waiting),
        blip("Permission", SampleSessions.permission),
        blip("Working", SampleSessions.working),
        blip("Idle", SampleSessions.idle),
        Story(.atoms, "RadarBlip", "Tag leading", size: blipSize, theme: .radar) { _ in
            RadarBlip(SampleSessions.permission, tagLeads: true)
        },
    ]

    static let radarOrganisms: [Story] = [
        scope("Typical", SampleSessions.typical),
        scope("Twelve sessions", SampleSessions.many),
        scope("All quiet", []),
        Story(.organisms, "RadarScope", "Typical, sweeping", size: CGSize(width: 312, height: 312), theme: .radar) { _ in
            // The sweep's first frame; it turns once every four seconds in the app.
            RadarScope(SampleSessions.typical).radarTheme(.radar, motion: .full)
        },
        contactStory("Question", SampleSessions.waiting, height: 330),
        contactStory("Question, can't reply here", SampleSessions.waitingCantReply, height: 220),
        contactStory("Permission", SampleSessions.permission, height: 250),
        contactStory("Permission timed out", SampleSessions.permissionExpired, height: 220),
        contactStory("Nobody calling", nil, height: 80),
    ]

    static let radarTemplates: [Story] = [
        radarPopover("Typical", SampleSessions.typical),
        radarPopover("Everything waiting", SampleSessions.allWaiting),
        radarPopover("Question calling", [SampleSessions.working, SampleSessions.waiting, SampleSessions.idle]),
        radarPopover("Twelve sessions", SampleSessions.many),
        radarPopover("All quiet", []),
    ]

    private static let blipSize = CGSize(width: 260, height: 56)

    private static func blip(_ name: String, _ session: SessionCardModel) -> Story {
        Story(.atoms, "RadarBlip", name, size: blipSize, theme: .radar) { _ in
            RadarBlip(session)
        }
    }

    private static func scope(_ name: String, _ sessions: [SessionCardModel]) -> Story {
        Story(.organisms, "RadarScope", name, size: CGSize(width: 312, height: 312), theme: .radar) { _ in
            // Reduced motion pins the sweep, so the snapshot is the same on every run.
            RadarScope(sessions).radarTheme(.radar, motion: .reduced)
        }
    }

    private static func contactStory(_ name: String, _ session: SessionCardModel?, height: CGFloat) -> Story {
        let hasField = session.map { $0.status == .waiting && $0.canReply } ?? false
        return Story(
            .organisms,
            "RadarContact",
            name,
            size: CGSize(width: 468, height: height),
            usesAppKitControls: hasField,
            theme: .radar,
        ) { context in
            StateHost("") { draft in
                RadarContact(session, draft: draft, actions: .logging(to: context))
            }
        }
    }

    /// Room for the contact panel: none, a permission request, or a question with replies.
    private static func popoverHeight(for callingIn: SessionCardModel?) -> CGFloat {
        switch callingIn?.status {
        case .waiting: 800
        case .permission: 720
        default: 600
        }
    }

    private static func radarPopover(_ name: String, _ sessions: [SessionCardModel]) -> Story {
        // The contact panel shows the most urgent caller; a text field only when that's a question.
        let callingIn = contact(selected: nil, in: sessions)
        let hasField = callingIn.map { $0.status == .waiting && $0.canReply } ?? false
        return Story(
            .templates,
            "RadarPopover",
            name,
            size: CGSize(width: 492, height: popoverHeight(for: callingIn)),
            usesAppKitControls: hasField,
            theme: .radar,
        ) { context in
            StateHost([String: String]()) { drafts in
                RadarPopover(
                    sessions: sessions,
                    drafts: drafts,
                    actions: .logging(to: context),
                    onOpenCmux: context.action("open cmux"),
                    motion: .reduced,
                )
            }
        }
    }
}
