public import SwiftUI

/// "Agents" title, the status summary line and the header buttons.
public struct PopoverHeader: View {
    let summary: StatusSummary
    let onSearch: () -> Void
    let onSettings: () -> Void

    @Environment(\.radarTheme) private var theme

    public init(summary: StatusSummary, onSearch: @escaping () -> Void, onSettings: @escaping () -> Void) {
        self.summary = summary
        self.onSearch = onSearch
        self.onSettings = onSettings
    }

    public var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: theme.metrics.space2) {
                Text("Agents")
                    .font(theme.type.title)
                    .foregroundStyle(theme.color(\.textPrimary))
                Text(summaryLine(summary))
                    .font(theme.type.subtitle)
                    .foregroundStyle(summary.needingYou > 0 ? theme.status(.waiting) : theme.color(\.textTertiary))
            }
            Spacer()
            IconButton("magnifyingglass", label: "Search sessions", action: onSearch)
            IconButton("gearshape", label: "Settings", action: onSettings)
        }
        .padding(.horizontal, theme.metrics.space16)
        .padding(.top, theme.metrics.popoverHeaderTop)
        .padding(.bottom, theme.metrics.space10)
    }
}

/// Keyboard hints and the "Open cmux" link.
public struct PopoverFooter: View {
    let onOpenCmux: () -> Void

    @Environment(\.radarTheme) private var theme

    public init(onOpenCmux: @escaping () -> Void) {
        self.onOpenCmux = onOpenCmux
    }

    public var body: some View {
        HStack(spacing: theme.metrics.space6) {
            KeyHint("⌘1–9")
            Text("answer ·").font(theme.type.caption).foregroundStyle(theme.color(\.textTertiary))
            KeyHint("⇥")
            Text("next").font(theme.type.caption).foregroundStyle(theme.color(\.textTertiary))
            Spacer()
            Button("Open cmux", action: onOpenCmux)
                .buttonStyle(.plain)
                .font(theme.type.link)
                .foregroundStyle(theme.status(.working))
        }
        .padding(.horizontal, theme.metrics.space16)
        .padding(.vertical, theme.metrics.space10)
        .overlay(alignment: .top) {
            Rectangle().fill(theme.color(\.borderSubtle)).frame(height: theme.metrics.hairline)
        }
    }
}
