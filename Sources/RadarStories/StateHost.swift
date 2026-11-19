internal import SwiftUI

/// Owns a piece of state for a story or playground, so components that take a `Binding`
/// (reply drafts) are interactive in the catalog and still render deterministically in snapshots.
struct StateHost<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initial)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
