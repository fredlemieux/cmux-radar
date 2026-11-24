public import RadarCore

/// What one cmux event frame means to Radar.
public enum CmuxSignal: Equatable, Sendable {
    /// A change the reducer applies as is.
    case event(RadarEvent)
    /// An agent is blocked on a permission, question or plan. The stream redacts the text, so the
    /// caller fetches the Feed item by `requestID` (`feed.list`) and builds the decision from it.
    case decisionPending(SessionContext, requestID: String, tool: String, stamp: Stamp)
    /// The subscription ack. `gap` means events were lost: re-bootstrap before continuing.
    case resumed(gap: Bool, nextSeq: UInt64)
    /// Heartbeats, duplicates and events Radar doesn't use.
    case ignored
}

/// Decodes one NDJSON line from `cmux events`. Never throws: anything unreadable is `.ignored`.
public func decodeFrame(_ line: String) -> CmuxSignal {
    if let frame = decodeJSON(WireFrame.self, from: line) {
        return signal(for: frame)
    }
    return .ignored
}

func signal(for frame: WireFrame) -> CmuxSignal {
    if frame.type == "ack" {
        return resumed(frame.resume)
    }
    if frame.type == "event", let seq = frame.seq, let time = frame.occurredAt.flatMap(cmuxDate) {
        return eventSignal(frame, stamp: Stamp(seq: seq, time: time))
    }
    return .ignored
}

func resumed(_ resume: WireResume?) -> CmuxSignal {
    if let nextSeq = resume?.nextSeq {
        return .resumed(gap: resume?.gap == true, nextSeq: nextSeq)
    }
    return .ignored
}

func eventSignal(_ frame: WireFrame, stamp: Stamp) -> CmuxSignal {
    let name = frame.name ?? ""
    if name == "feed.item.resolved" {
        return resolved(frame.payload?.requestID, stamp: stamp)
    }
    if name == "feed.item.completed", frame.payload?.hookEventName == "PermissionRequest" {
        return resolved(frame.payload?.hookRequestID, stamp: stamp)
    }
    if name.hasPrefix("agent.hook."), let context = sessionContext(frame) {
        return hookSignal(frame.payload, context: context, stamp: stamp)
    }
    return .ignored
}

func resolved(_ requestID: String?, stamp: Stamp) -> CmuxSignal {
    if let requestID {
        return .event(.decisionResolved(requestID: requestID, stamp: stamp))
    }
    return .ignored
}

/// The session a hook frame belongs to. The payload's surface and workspace win; the frame's are
/// the fallback (the payload's surface is sometimes null).
func sessionContext(_ frame: WireFrame) -> SessionContext? {
    if let payload = frame.payload, let sessionID = payload.sessionID, let cwd = payload.cwd {
        return SessionContext(
            id: SessionID(sessionID),
            cwd: cwd,
            workspaceID: payload.workspaceID ?? frame.workspaceID,
            surfaceID: payload.surfaceID ?? frame.surfaceID,
        )
    }
    return nil
}

/// cmux sends each hook twice, `received` then `completed`; Radar takes one phase per hook.
///
/// The `PermissionRequest` mapping (here and the `feed.item.completed` one above) is inferred from
/// the request id format; confirm with a live capture (docs/SPEC.md open question 6).
func hookSignal(_ payload: WirePayload?, context: SessionContext, stamp: Stamp) -> CmuxSignal {
    let hook = payload?.hookEventName ?? ""
    let phase = payload?.phase ?? ""
    if phase == "received" {
        return receivedHook(hook, payload: payload, context: context, stamp: stamp)
    }
    if phase == "completed", hook == "Stop" {
        return .event(.stopped(context, stamp: stamp))
    }
    return .ignored
}

func receivedHook(_ hook: String, payload: WirePayload?, context: SessionContext, stamp: Stamp) -> CmuxSignal {
    switch hook {
    case "UserPromptSubmit":
        .event(.promptSubmitted(context, stamp: stamp))
    case "PreToolUse":
        .event(.toolStarted(context, stamp: stamp))
    case "SessionEnd":
        .event(.sessionEnded(context.id, stamp: stamp))
    case "PermissionRequest":
        permissionRequested(payload, context: context, stamp: stamp)
    default:
        .ignored
    }
}

func permissionRequested(_ payload: WirePayload?, context: SessionContext, stamp: Stamp) -> CmuxSignal {
    if let requestID = payload?.hookRequestID {
        return .decisionPending(context, requestID: requestID, tool: payload?.toolName ?? "", stamp: stamp)
    }
    return .ignored
}
