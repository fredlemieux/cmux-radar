// MUTATION-VERIFIED: killed 22/22 mutants on 2026-11-19 (SuggestedReplies.swift)
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

        @Test func `treats a numbered sublist under the last item as detail`() {
            #expect(suggestedReplies(from: "1. Foo\n2. Bar\n   1. x\n   2. y").map(\.label) == ["Foo", "Bar"])
        }

        @Test func `treats a numbered sublist as detail`() {
            #expect(suggestedReplies(from: "1. Foo\n   1. a\n   2. b\n2. Bar").map(\.label) == ["Foo", "Bar"])
        }

        @Test func `keeps only the closing list when two are separated by a blank line`() {
            #expect(suggestedReplies(from: "1. Read\n2. Wrote\n\n1. Ship\n2. Wait").map(\.label) == ["Ship", "Wait"])
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
    @Test func `a blank line is in the list region`() {
        #expect(isInListRegion(""))
    }

    @Test func `an indented line is in the list region`() {
        #expect(isInListRegion("   - safer"))
    }

    @Test func `an unindented item is in the list region`() {
        #expect(isInListRegion("1. Ship"))
    }

    @Test func `unindented prose ends the list region`() {
        #expect(!isInListRegion("Then:"))
    }

    @Test func `the list level is the shallowest item indent`() {
        #expect(listLevel(["   2. y", "   1. x", "2. Bar", "   - note"]) == 0)
    }

    @Test func `a region without items has no level`() {
        #expect(listLevel(["   - note", ""]) == nil)
    }

    @Test func `a line at the level is at the level`() {
        #expect(isAtLevel("1. a", 0))
    }

    @Test func `a deeper line is not at the level`() {
        #expect(!isAtLevel("   1. a", 0))
    }

    @Test func `a blank line is never at the level`() {
        #expect(!isAtLevel("", 0))
    }

    @Test func `the bottom item always starts the list`() {
        #expect(continuesUpwards(SuggestedReply(number: 7, label: "x"), before: nil))
    }

    @Test func `the item above must be one less`() {
        #expect(continuesUpwards(SuggestedReply(number: 2, label: "x"), before: SuggestedReply(number: 3, label: "y")))
    }

    @Test func `an item that restarts numbering ends the list`() {
        #expect(!continuesUpwards(SuggestedReply(number: 2, label: "x"), before: SuggestedReply(number: 1, label: "y")))
    }

    @Test func `counts leading whitespace`() {
        #expect(indentation("   - a") == 3)
    }

    @Test func `keeps markers inside a label`() {
        #expect(plainText(" Use `__init__` ") == "Use `__init__`")
    }

    @Test func `a lone marker is not a wrapper`() {
        #expect(!isWrapped("**", in: "**"))
    }

    @Test func `requires a space after the marker`() {
        #expect(listItem("1.5 GB") == nil)
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
