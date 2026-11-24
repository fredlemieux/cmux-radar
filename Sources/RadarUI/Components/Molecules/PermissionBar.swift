public import SwiftUI

/// The blocked command and the three decisions. Once the request has expired, the decisions
/// are gone and only "Answer in terminal" remains.
public struct PermissionBar: View {
    let permission: PermissionModel
    let onAllow: () -> Void
    let onAlways: () -> Void
    let onDeny: () -> Void
    let onJump: () -> Void

    @Environment(\.radarTheme) private var theme

    public init(
        _ permission: PermissionModel,
        onAllow: @escaping () -> Void,
        onAlways: @escaping () -> Void,
        onDeny: @escaping () -> Void,
        onJump: @escaping () -> Void,
    ) {
        self.permission = permission
        self.onAllow = onAllow
        self.onAlways = onAlways
        self.onDeny = onDeny
        self.onJump = onJump
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.space10) {
            CommandBlock(permission.command)
            if permission.expired {
                HStack {
                    Text("Timed out. The agent is asking in its terminal.")
                        .font(theme.type.caption)
                        .foregroundStyle(theme.color(\.textTertiary))
                    Spacer()
                }
                ActionButton("Answer in terminal ⌥⏎", style: .primary, action: onJump)
                    .accessibilityLabel("Answer in terminal")
                    .accessibilityHint("Shortcut: option return.")
            } else {
                HStack(spacing: theme.metrics.space6) {
                    ActionButton("Allow once", style: .primary, action: onAllow)
                    ActionButton("Always", action: onAlways)
                    ActionButton("Deny", action: onDeny)
                }
                if let expiresIn = permission.expiresIn {
                    Text(expiresIn)
                        .font(theme.type.caption.monospacedDigit())
                        .foregroundStyle(theme.color(\.textTertiary))
                }
            }
        }
    }
}
