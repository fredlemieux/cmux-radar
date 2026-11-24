// MUTATION-VERIFIED: n/a — FeedItems.swift has no operators Muter mutates (0 mutants on 2026-11-24)
import Foundation
@testable import RadarCmux
import RadarCore
import Testing

/// A `feed.list` response holding `items`, encoded the way cmux sends it.
private func feedList(_ items: [[String: Any?]]) -> Data {
    let text = json(["items": nil])
    let encoded = items.map(json).joined(separator: ",")
    return Data(text.replacingOccurrences(of: "null", with: "[\(encoded)]").utf8)
}

private func item(_ kind: String, requestID: String? = permissionRequestID, extra: [String: Any?] = [:]) -> [String: Any?] {
    var item: [String: Any?] = [
        "id": "DDDDDDDD-0000-0000-0000-000000000004",
        "kind": kind,
        "status": "pending",
        "workstream_id": sessionID,
        "cwd": cwd,
        "created_at": "2026-11-24T10:00:00Z",
        "request_id": requestID,
        "source": "claude",
    ]
    item.merge(extra) { _, new in new }
    return item
}

private func decision(_ item: [String: Any?]) -> PendingDecision? {
    decodeFeedList(feedList([item])).first?.decision
}

enum FeedItemsTests {
    struct PermissionRequest {
        @Test func `takes the command of a shell tool`() {
            let request = item(
                "permissionRequest",
                extra: ["tool_name": "Bash", "tool_input": json(["command": "pnpm db:migrate", "timeout": 60])],
            )
            #expect(decision(request) == .permission(requestID: permissionRequestID, tool: "Bash", input: "pnpm db:migrate"))
        }

        @Test func `keeps the raw input of other tools`() {
            let input = json(["file_path": "/Users/dev/code/api/README.md"])
            let request = item("permissionRequest", extra: ["tool_name": "Write", "tool_input": input])
            #expect(decision(request) == .permission(requestID: permissionRequestID, tool: "Write", input: input))
        }

        @Test func `keeps input that isn't JSON`() {
            let request = item("permissionRequest", extra: ["tool_name": "Bash", "tool_input": "ls -la"])
            #expect(decision(request) == .permission(requestID: permissionRequestID, tool: "Bash", input: "ls -la"))
        }

        @Test func `has an empty tool and input when cmux sends neither`() {
            #expect(decision(item("permissionRequest")) == .permission(requestID: permissionRequestID, tool: "", input: ""))
        }

        @Test func `belongs to its workstream`() {
            let decoded = decodeFeedList(feedList([item("permissionRequest")])).first
            #expect(decoded?.sessionID == SessionID(sessionID))
        }

        @Test func `keeps its working directory`() {
            #expect(decodeFeedList(feedList([item("permissionRequest")])).first?.cwd == cwd)
        }
    }

    struct QuestionItems {
        private let options: [[String: Any?]] = [
            ["id": "opt-1", "label": "Feature flag", "description": "Ship dark"],
            ["id": "opt-2", "label": "Everyone", "description": nil],
        ]

        @Test func `reads every question asked`() {
            let questions: [[String: Any?]] = [
                ["header": "Rollout", "id": "q-1", "multi_select": false, "prompt": "How should it ship?", "options": options],
                ["header": "Docs", "id": "q-2", "multi_select": true, "prompt": "Update the docs?", "options": []],
            ]
            let expected = PendingDecision.question(requestID: permissionRequestID, questions: [
                Question(
                    prompt: "How should it ship?",
                    options: [QuestionOption(id: "opt-1", label: "Feature flag"), QuestionOption(id: "opt-2", label: "Everyone")],
                ),
                Question(prompt: "Update the docs?", options: []),
            ])
            #expect(decision(item("question", extra: ["questions": questions])) == expected)
        }

        @Test func `falls back to the single prompt`() {
            let request = item("question", extra: ["question_prompt": "How should it ship?", "question_options": options])
            let expected = PendingDecision.question(requestID: permissionRequestID, questions: [
                Question(
                    prompt: "How should it ship?",
                    options: [QuestionOption(id: "opt-1", label: "Feature flag"), QuestionOption(id: "opt-2", label: "Everyone")],
                ),
            ])
            #expect(decision(request) == expected)
        }

        @Test func `uses the label when an option has no id`() {
            let request = item("question", extra: ["question_prompt": "Ship?", "question_options": [["label": "Yes"]]])
            let expected = PendingDecision.question(requestID: permissionRequestID, questions: [
                Question(prompt: "Ship?", options: [QuestionOption(id: "Yes", label: "Yes")]),
            ])
            #expect(decision(request) == expected)
        }

        @Test func `has no questions when cmux sends none`() {
            #expect(decision(item("question")) == .question(requestID: permissionRequestID, questions: []))
        }
    }

    struct ExitPlan {
        @Test func `takes the plan from the tool input`() {
            let request = item("exitPlan", extra: ["tool_input": json(["plan": "1. Migrate\n2. Backfill"])])
            #expect(decision(request) == .plan(requestID: permissionRequestID, plan: "1. Migrate\n2. Backfill"))
        }

        @Test func `has an empty plan when the input has none`() {
            let request = item("exitPlan", extra: ["tool_input": json(["plan": 3])])
            #expect(decision(request) == .plan(requestID: permissionRequestID, plan: ""))
        }
    }

    struct Skipped {
        @Test func `telemetry items are skipped`() {
            #expect(decodeFeedList(feedList([item("toolUse", requestID: nil), item("stop", requestID: nil)])).isEmpty)
        }

        @Test func `a decision kind without a request id is skipped`() {
            #expect(decodeFeedList(feedList([item("permissionRequest", requestID: nil)])).isEmpty)
        }

        @Test func `an unknown kind with a request id is skipped`() {
            #expect(decodeFeedList(feedList([item("toolResult")])).isEmpty)
        }

        @Test func `an item without a workstream is skipped`() {
            #expect(decodeFeedList(feedList([item("permissionRequest", extra: ["workstream_id": nil])])).isEmpty)
        }

        @Test func `a response that isn't a list is empty`() {
            #expect(decodeFeedList(Data("{}".utf8)).isEmpty)
        }

        @Test func `only decision items are kept`() {
            let list = feedList([item("stop", requestID: nil), item("permissionRequest"), item("toolUse", requestID: nil)])
            #expect(decodeFeedList(list).count == 1)
        }
    }

    struct DecisionsListed {
        @Test func `lists every request id Feed holds`() {
            let other = "\(sessionID)-PermissionRequest-AskUserQuestion-1764000000001"
            let decisions = decodeFeedList(feedList([item("permissionRequest"), item("question", requestID: other)]))
            #expect(decisionsListed(decisions, stamp: fixtureStamp) == .decisionsListed(
                requestIDs: [permissionRequestID, other],
                stamp: fixtureStamp,
            ))
        }

        @Test func `an empty Feed lists nothing`() {
            #expect(decisionsListed([], stamp: fixtureStamp) == .decisionsListed(requestIDs: [], stamp: fixtureStamp))
        }
    }
}
