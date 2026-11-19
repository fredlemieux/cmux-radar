internal import RadarUI
internal import SwiftUI

nonisolated extension Playgrounds {
    static let atoms: [Playground] = [
        Playground("StatusDot") { _, scheme, zoom in StatusDotPlayground(scheme: scheme, zoom: zoom) },
        Playground("CountBadge") { _, scheme, zoom in CountBadgePlayground(scheme: scheme, zoom: zoom) },
        Playground("KeyHint") { _, scheme, zoom in KeyHintPlayground(scheme: scheme, zoom: zoom) },
        Playground("IconButton") { context, scheme, zoom in IconButtonPlayground(context: context, scheme: scheme, zoom: zoom) },
        Playground("ReplyChip") { context, scheme, zoom in ReplyChipPlayground(context: context, scheme: scheme, zoom: zoom) },
        Playground("ActionButton") { context, scheme, zoom in ActionButtonPlayground(context: context, scheme: scheme, zoom: zoom) },
        Playground("CommandBlock") { _, scheme, zoom in CommandBlockPlayground(scheme: scheme, zoom: zoom) },
        Playground("ProgressBar") { _, scheme, zoom in ProgressBarPlayground(scheme: scheme, zoom: zoom) },
        Playground("SectionLabel") { _, scheme, zoom in SectionLabelPlayground(scheme: scheme, zoom: zoom) },
    ]
}

private struct StatusDotPlayground: View {
    let scheme: ColorScheme
    let zoom: Double
    @State private var status = SessionStatus.waiting
    @State private var pulsing = true
    @State private var reduceMotion = false

    var body: some View {
        PlaygroundLayout(scheme: scheme, zoom: zoom) {
            StatusDot(status, pulsing: pulsing).radarTheme(.classic, motion: reduceMotion ? .reduced : .full)
        } controls: {
            StatusPicker(title: "Status", status: $status)
            Toggle("Pulsing", isOn: $pulsing)
            Toggle("Reduce Motion", isOn: $reduceMotion)
        }
    }
}

private struct CountBadgePlayground: View {
    let scheme: ColorScheme
    let zoom: Double
    @State private var count = 2
    @State private var permission = false

    var body: some View {
        PlaygroundLayout(scheme: scheme, zoom: zoom) {
            CountBadge(count, attention: permission ? .permission : .waiting)
        } controls: {
            Stepper("Count: \(count)", value: $count, in: -5 ... 250)
            Toggle("Permission colour", isOn: $permission)
        }
    }
}

private struct KeyHintPlayground: View {
    let scheme: ColorScheme
    let zoom: Double
    @State private var keys = "⌘1"

    var body: some View {
        PlaygroundLayout(scheme: scheme, zoom: zoom) {
            KeyHint(keys)
        } controls: {
            TextField("Keys", text: $keys)
        }
    }
}

private struct IconButtonPlayground: View {
    let context: StoryContext
    let scheme: ColorScheme
    let zoom: Double
    @State private var symbol = "arrow.right"
    @State private var label = "Send reply"
    @State private var filled = true
    @State private var enabled = true

    var body: some View {
        PlaygroundLayout(scheme: scheme, zoom: zoom) {
            IconButton(symbol, label: label, style: filled ? .filled : .plain, action: context.action("tap"))
                .disabled(!enabled)
        } controls: {
            TextField("SF Symbol", text: $symbol)
            TextField("Accessibility label", text: $label)
            Toggle("Filled", isOn: $filled)
            Toggle("Enabled", isOn: $enabled)
        }
    }
}

private struct ReplyChipPlayground: View {
    let context: StoryContext
    let scheme: ColorScheme
    let zoom: Double
    @State private var index = 1
    @State private var label = "Build it"
    @State private var highlighted = false

    var body: some View {
        PlaygroundLayout(scheme: scheme, zoom: zoom) {
            ReplyChip(index: index, label: label, highlighted: highlighted, action: context.action("pick \(index)"))
        } controls: {
            Stepper("Number: \(index)", value: $index, in: 1 ... 9)
            TextField("Label", text: $label)
            Toggle("Highlighted", isOn: $highlighted)
        }
    }
}

private struct ActionButtonPlayground: View {
    let context: StoryContext
    let scheme: ColorScheme
    let zoom: Double
    @State private var title = "Allow once"
    @State private var primary = true
    @State private var enabled = true

    var body: some View {
        PlaygroundLayout(scheme: scheme, zoom: zoom) {
            ActionButton(title, style: primary ? .primary : .outline, action: context.action(title.lowercased()))
                .disabled(!enabled)
        } controls: {
            TextField("Title", text: $title)
            Toggle("Primary", isOn: $primary)
            Toggle("Enabled", isOn: $enabled)
        }
    }
}

private struct CommandBlockPlayground: View {
    let scheme: ColorScheme
    let zoom: Double
    @State private var text = "$ bun Tools/myagora.ts --days 7"

    var body: some View {
        PlaygroundLayout(scheme: scheme, zoom: zoom) {
            CommandBlock(text)
        } controls: {
            TextField("Command", text: $text, axis: .vertical)
                .lineLimit(2 ... 6)
        }
    }
}

private struct ProgressBarPlayground: View {
    let scheme: ColorScheme
    let zoom: Double
    @State private var fraction = 0.72

    var body: some View {
        PlaygroundLayout(scheme: scheme, zoom: zoom) {
            ProgressBar(fraction)
        } controls: {
            Slider(value: $fraction, in: -0.2 ... 1.2) {
                Text("Fraction \(fraction, format: .number.precision(.fractionLength(2)))")
            }
        }
    }
}

private struct SectionLabelPlayground: View {
    let scheme: ColorScheme
    let zoom: Double
    @State private var title = "Needs you"
    @State private var count = 2
    @State private var status = SessionStatus.waiting

    var body: some View {
        PlaygroundLayout(scheme: scheme, zoom: zoom) {
            SectionLabel(title, count: count, status: status)
        } controls: {
            TextField("Title", text: $title)
            Stepper("Count: \(count)", value: $count, in: 0 ... 99)
            StatusPicker(title: "Status", status: $status)
        }
    }
}
