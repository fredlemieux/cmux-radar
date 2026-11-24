public import SwiftUI

/// The agent's question, in full. Never truncated: it's the point of the card.
public struct QuestionBlock: View {
    let question: String

    @Environment(\.radarTheme) private var theme

    public init(_ question: String) {
        self.question = question
    }

    public var body: some View {
        Text(question)
            .font(theme.type.question)
            .foregroundStyle(theme.color(\.textPrimary))
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(theme.type.questionLineSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, theme.metrics.space12)
            .padding(.vertical, theme.metrics.space10)
            .background(RoundedRectangle(cornerRadius: theme.metrics.radiusControl).fill(theme.color(\.surfaceInset)))
            .textSelection(.enabled)
            .accessibilityLabel("Question: \(question)")
    }
}
