public import SwiftUI

/// A wrapping row of quick replies.
public struct ReplyChips: View {
    let options: [ReplyOption]
    let highlighted: Int?
    let onPick: (ReplyOption) -> Void

    @Environment(\.radarTheme) private var theme

    public init(_ options: [ReplyOption], highlighted: Int? = nil, onPick: @escaping (ReplyOption) -> Void) {
        self.options = options
        self.highlighted = highlighted
        self.onPick = onPick
    }

    public var body: some View {
        FlowLayout(spacing: theme.metrics.space6) {
            ForEach(options) { option in
                ReplyChip(index: option.index, label: option.label, highlighted: option.index == highlighted) {
                    onPick(option)
                }
            }
        }
    }
}

/// Lays children out left to right, wrapping onto new lines when the width runs out.
struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, width maxWidth: CGFloat) -> [Row] {
        var rows = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > maxWidth, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            let last = rows.count - 1
            rows[last].width += (rows[last].indices.isEmpty ? 0 : spacing) + size.width
            rows[last].height = max(rows[last].height, size.height)
            rows[last].indices.append(index)
        }
        return rows
    }
}
