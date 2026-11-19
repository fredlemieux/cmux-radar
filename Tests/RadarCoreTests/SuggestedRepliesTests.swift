// MUTATION-VERIFIED: killed 14/14 mutants on 2026-11-19 (SuggestedReplies.swift)
import PropertyBased
@testable import RadarCore
import Testing

struct SuggestedRepliesTests {
    @Test func `offers nothing without a message`() {
        #expect(suggestedReplies(from: nil).isEmpty)
    }

    @Test func `offers each item of a closing numbered list`() {
        let message = "Which should I do?\n1. Feature flag\n2. Everyone"
        #expect(suggestedReplies(from: message) == [
            SuggestedReply(number: 1, label: "Feature flag"),
            SuggestedReply(number: 2, label: "Everyone"),
        ])
    }

    @Test func `accepts a parenthesis after the number`() {
        #expect(suggestedReplies(from: "1) Yes\n2) No").map(\.label) == ["Yes", "No"])
    }

    @Test func `ignores blank lines after the list`() {
        #expect(suggestedReplies(from: "1. Yes\n2. No\n\n  \n").count == 2)
    }

    @Test func `accepts indented items`() {
        #expect(suggestedReplies(from: "  1. Yes\n  2. No").count == 2)
    }

    @Test func `trims the label`() {
        #expect(suggestedReplies(from: "1.   Yes  \n2. No").first?.label == "Yes")
    }

    @Test func `offers nothing when text follows the list`() {
        #expect(suggestedReplies(from: "1. Yes\n2. No\nLet me know.").isEmpty)
    }

    @Test func `offers nothing for a single item`() {
        #expect(suggestedReplies(from: "Next:\n1. Deploy").isEmpty)
    }

    @Test func `offers nothing when numbering skips`() {
        #expect(suggestedReplies(from: "1. Yes\n3. No").isEmpty)
    }

    @Test func `offers nothing when numbering starts above one`() {
        #expect(suggestedReplies(from: "2. Yes\n3. No").isEmpty)
    }

    @Test func `offers nothing without a list`() {
        #expect(suggestedReplies(from: "All done. Tests pass.").isEmpty)
    }

    @Test func `keeps only the closing list`() {
        let message = "1. Read\n2. Wrote\nWhat next?\n1. Ship\n2. Wait"
        #expect(suggestedReplies(from: message).map(\.label) == ["Ship", "Wait"])
    }

    @Test func `numbers every offer from one in order`() async {
        let line = Gen.oneOf(
            Gen.always("1. Yes"),
            Gen.always("2. No"),
            Gen.always("3. Maybe"),
            Gen.always("Text"),
            Gen.always(""),
            Gen.always("2) Later"),
        )
        await propertyCheck(input: line.array(of: 0 ... 8)) { lines in
            let numbers = suggestedReplies(from: lines.joined(separator: "\n")).map(\.number)
            #expect(numbers == Array(1 ..< numbers.count + 1))
        }
    }
}

extension SuggestedRepliesTests {
    struct WithRealisticAgentFormatting {
        @Test func `keeps items that carry nested bullets`() {
            let message = "Options:\n1. Flag\n   - safer\n2. Everyone\n   - faster"
            #expect(suggestedReplies(from: message).map(\.label) == ["Flag", "Everyone"])
        }

        @Test func `keeps items separated by blank lines`() {
            #expect(suggestedReplies(from: "Pick one:\n\n1. Flag\n\n2. Everyone").count == 2)
        }

        @Test func `reads bold numbers`() {
            #expect(suggestedReplies(from: "**1.** Flag\n**2.** Everyone").map(\.number) == [1, 2])
        }

        @Test func `drops markdown emphasis from labels`() {
            #expect(suggestedReplies(from: "1. **Feature flag**\n2. `Everyone`").map(\.label) == ["Feature flag", "Everyone"])
        }

        @Test func `reads windows line endings`() {
            #expect(suggestedReplies(from: "1. Yes\r\n2. No\r\n").count == 2)
        }

        @Test func `ignores decimals that look like numbering`() {
            #expect(suggestedReplies(from: "Disk:\n1.5 GB free\n2.0 is required").isEmpty)
        }

        @Test func `stops at prose above the list`() {
            #expect(suggestedReplies(from: "3. Earlier\nThen:\n1. Ship\n2. Wait").map(\.label) == ["Ship", "Wait"])
        }
    }
}

struct ListItemTests {
    @Test func `reads a dotted item`() {
        #expect(listItem("4. Four") == SuggestedReply(number: 4, label: "Four"))
    }

    @Test func `reads a multi-digit number`() {
        #expect(listItem("12. Twelve")?.number == 12)
    }

    @Test func `rejects a number without a marker`() {
        #expect(listItem("4 Four") == nil)
    }

    @Test func `rejects an empty label`() {
        #expect(listItem("4.   ") == nil)
    }

    @Test func `rejects a line without a number`() {
        #expect(listItem("- Four") == nil)
    }
}

struct IsASCIIDigitTests {
    @Test func `accepts an ascii digit`() {
        #expect(isASCIIDigit("7"))
    }

    @Test func `rejects a letter`() {
        #expect(!isASCIIDigit("a"))
    }

    @Test func `rejects a non-ascii digit`() {
        #expect(!isASCIIDigit("٣"))
    }
}

struct ListItemRuleTests {
    @Test func `requires a space after the marker`() {
        #expect(listItem("1.5 GB") == nil)
    }

    @Test func `a blank line belongs to a list`() {
        #expect(belongsToList("   "))
    }

    @Test func `an indented detail line belongs to a list`() {
        #expect(belongsToList("   - safer"))
    }

    @Test func `unindented prose does not belong to a list`() {
        #expect(!belongsToList("Then:"))
    }

    @Test func `an empty line is not indented`() {
        #expect(!isIndented(""))
    }

    @Test func `a dot is a list marker`() {
        #expect(isListMarker("."))
    }

    @Test func `a parenthesis is a list marker`() {
        #expect(isListMarker(")"))
    }

    @Test func `a colon is not a list marker`() {
        #expect(!isListMarker(":"))
    }

    @Test func `drops leading underscores bold`() {
        #expect(withoutEmphasisMarker("__1.") == "1.")
    }

    @Test func `drops underscores emphasis from a label`() {
        #expect(plainText(" __Ship__ ") == "Ship")
    }
}
