public import Foundation

/// Something that happened, already decoded from cmux (events, Feed, notifications, state files).
///
/// The adapters that turn cmux frames into these live outside the reducer, so the reducer stays a
/// pure function of `(state, event)`.
public enum RadarEvent: Equatable, Sendable {
    /// `agent.hook.UserPromptSubmit`: the user sent a prompt; the agent is working.
    case promptSubmitted(SessionContext, stamp: Stamp)
    /// `agent.hook.PreToolUse` or a Feed `toolUse` item: the agent is working.
    case toolStarted(SessionContext, stamp: Stamp)
    /// `feed.item.received` of kind `permissionRequest`, `question` or `exitPlan`.
    case decisionRequested(SessionContext, PendingDecision, stamp: Stamp)
    /// `feed.item.resolved` / `feed.item.completed`. Feed keys these by request id, so the reducer
    /// finds the session holding it.
    case decisionResolved(requestID: String, stamp: Stamp)
    /// `agent.hook.Stop` with phase `completed`: the agent finished its turn.
    case stopped(SessionContext, stamp: Stamp)
    /// A cmux "Waiting" notification for a surface: fallback when hooks are missing.
    case waitingNotification(surfaceID: String, stamp: Stamp)
    /// A bootstrap read of `feed.list`: the request ids Feed still holds. Any other open decision
    /// was resolved while Radar wasn't listening (a resume gap) and is closed.
    case decisionsListed(requestIDs: Set<String>, stamp: Stamp)
    /// `agent.hook.SessionEnd`.
    case sessionEnded(SessionID, stamp: Stamp)
    /// The cmux tab title, from `notification.list`.
    case titleChanged(SessionID, title: String)
    /// Text fetched by the resolver (the event stream redacts it).
    case textResolved(SessionID, lastUserMessage: String?, lastAgentMessage: String?)
    /// The clock moved on: ages waiting sessions to idle and drops long-ended ones.
    case tick(Date)
}
