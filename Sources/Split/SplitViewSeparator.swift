import SwiftUI

public struct SplitViewSeparator: View {
    @Environment(\.splitViewDragging) private var isDragging
    @Environment(\.splitViewAxis) private var axis
    @Environment(\.splitViewDragIndicator) private var indicatorVisibility
    @Environment(\.isDragEnabled) private var isDragEnabled
    @State private var isHovering: Bool = false

    public var body: some View {
#if os(macOS)
        Divider()
            .frame(
                width: axis == .horizontal ? 1 : nil,
                height: axis == .vertical ? 1 : nil
            )
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
#else
        Rectangle()
            .foregroundStyle(.background)
            .frame(
                width: axis == .horizontal ? 2 : nil,
                height: axis == .vertical ? 2 : nil
            )
            .overlay {
                ZStack {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.background)

                    Image(systemName: "arrow.up.and.down")
                        .foregroundStyle(.foreground)
                        .imageScale(.small)
                }
                .compositingGroup()
                .drawingGroup()
                .imageScale(.large)
                .font(.title3)
                .blur(radius: isIndicatorVisible ? 0 : 4)
                .opacity(isIndicatorVisible ? 1 : 0)
                .scaleEffect(isIndicatorVisible ? 1 : 0.9)
            }
            .contentShape(.interaction, .rect.inset(by: -5))
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
