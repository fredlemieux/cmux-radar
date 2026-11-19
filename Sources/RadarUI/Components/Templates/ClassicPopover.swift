public import SwiftUI

/// The Classic skin's menu bar popover: header, session list, footer.
public struct ClassicPopover: View {
    let sessions: [SessionCardModel]
    let actions: SessionActions
    let onSearch: () -> Void
    let onSettings: () -> Void
    let onOpenCmux: () -> Void

    @Environment(\.radarTheme) private var theme

    public init(
        sessions: [SessionCardModel],
        actions: SessionActions,
        onSearch: @escaping () -> Void = {},
        onSettings: @escaping () -> Void = {},
        onOpenCmux: @escaping () -> Void = {},
    ) {
        self.sessions = sessions
        self.actions = actions
        self.onSearch = onSearch
        self.onSettings = onSettings
        self.onOpenCmux = onOpenCmux
    }

    public var body: some View {
        VStack(spacing: 0) {
            PopoverHeader(summary: StatusSummary(sessions), onSearch: onSearch, onSettings: onSettings)
            SessionList(sessions, actions: actions)
                .frame(maxHeight: .infinity, alignment: .top)
            PopoverFooter(onOpenCmux: onOpenCmux)
        }
        .frame(width: theme.metrics.popoverWidth)
        .background(theme.color(\.surfacePopover))
        .clipShape(RoundedRectangle(cornerRadius: theme.metrics.radiusPopover))
        .overlay(RoundedRectangle(cornerRadius: theme.metrics.radiusPopover).strokeBorder(theme.color(\.borderSubtle)))
    }
}
