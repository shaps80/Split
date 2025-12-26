import SwiftUI

internal extension SplitView {
    struct SplitDetentModifier: ViewModifier {
        @Environment(\.self) private var environment
        var axis: Axis
        var proxy: GeometryProxy
        var detent: SplitDetent

        func body(content: Content) -> some View {
            let maxValue = axis == .horizontal ? proxy.size.width : proxy.size.height
            let length = detent.id.length(
                in: .init(
                    environment: environment,
                    maxDetentValue: maxValue
                )
            )

            content
                .frame(
                    width: axis == .horizontal ? length : nil,
                    height: axis == .vertical ? length : nil,
                    alignment: .topLeading
                )
        }
    }
}
