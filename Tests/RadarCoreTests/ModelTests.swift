// MUTATION-VERIFIED: killed 1/1 mutants on 2026-11-19 (Model.swift)
@testable import RadarCore
import Testing

struct AgentKindTests {
    @Test func `reads claude from the id prefix`() {
        #expect(AgentKind(sessionID: SessionID("claude-3f2a")) == .claude)
    }

    @Test func `reads codex from the id prefix`() {
        #expect(AgentKind(sessionID: SessionID("codex-91bc")) == .codex)
    }

    @Test func `keeps an unknown prefix`() {
        #expect(AgentKind(sessionID: SessionID("gemini-7d")) == .other("gemini"))
    }
}

struct DefaultTitleTests {
    @Test func `is the last path component`() {
        #expect(defaultTitle(cwd: "/Users/dev/code/billing", id: SessionID("claude-1")) == "billing")
    }

    @Test func `ignores a trailing slash`() {
        #expect(defaultTitle(cwd: "/Users/dev/code/billing/", id: SessionID("claude-1")) == "billing")
    }

    @Test func `falls back to the session id for the root`() {
        #expect(defaultTitle(cwd: "/", id: SessionID("claude-1")) == "claude-1")
    }
}

struct PendingDecisionTests {
    @Test func `a permission request needs permission`() {
        #expect(permission.state == .needsPermission)
    }

    @Test func `a question needs an answer`() {
        #expect(question.state == .needsAnswer)
    }

    @Test func `a plan needs approval`() {
        #expect(plan.state == .needsPlanApproval)
    }

    @Test func `exposes the permission request id`() {
        #expect(permission.requestID == "req-1")
    }

    @Test func `exposes the question request id`() {
        #expect(question.requestID == "req-2")
    }

    @Test func `exposes the plan request id`() {
        #expect(plan.requestID == "req-3")
    }
}

struct SessionIDTests {
    @Test func `orders by raw value`() {
        #expect(SessionID("claude-a") < SessionID("claude-b"))
    }

    @Test func `describes itself as its raw value`() {
        #expect(SessionID("claude-a").description == "claude-a")
    }
}
