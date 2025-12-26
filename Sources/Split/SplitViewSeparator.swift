import SwiftUI

public struct SplitViewSeparator: View {
    @Environment(\.splitViewDragging) private var isDragging
    @Environment(\.splitViewAxis) private var axis
    @Environment(\.splitViewDragIndicator) private var indicatorVisibility
    @Environment(\.isDragEnabled) private var isDragEnabled
    @State private var isHovering: Bool = false

    public var body: some View {
        Rectangle()
            .foregroundStyle(.background)
#if os(iOS) || os(tvOS)
            .frame(
                width: axis == .horizontal ? 8 : nil,
                height: axis == .vertical ? 8 : nil
            )
            .overlay {
                Capsule()
                    .foregroundStyle(.foreground)
                    .frame(
                        width: axis == .horizontal ? 4 : 40,
                        height: axis == .horizontal ? 40 : 4
                    )
                    .opacity(isIndicatorVisible ? 1 : 0)
                    .scaleEffect(isIndicatorVisible ? 1 : 0.9)
            }
#else
            .frame(
                width: axis == .horizontal ? 1 : nil,
                height: axis == .vertical ? 1 : nil
            )
#endif
#if os(macOS)
            .contentShape(.interaction, .rect.inset(by: -5))
            .onHover { hovering in
                isHovering = hovering
                if hovering, isDragEnabled {
                    switch axis {
                    case .horizontal:
                        NSCursor.resizeLeftRight.push()
                    case .vertical:
                        NSCursor.resizeUpDown.push()
                    }
                } else {
                    NSCursor.pop()
                }
            }
            .onChange(of: isDragging) { _, dragging in
                if !dragging && !isHovering {
                    NSCursor.pop()
                }
            }
#endif
    }

    private var isIndicatorVisible: Bool {
        switch indicatorVisibility {
        case .automatic: isDragging
        case .visible: true
        case .hidden: false
        }
    }
}
