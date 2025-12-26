import SwiftUI

public struct SplitView<Primary, Secondary, Separator>: View where Primary: View, Secondary: View, Separator: View {
    @Environment(\.accessibilityReduceMotion) private var isReduceMotionEnabled
    @Environment(\.splitViewElasticBehavior) private var elasticBehaviour
    @Environment(\.splitViewResizeBehavior) private var resizeBehavior
    @Environment(\.self) private var environment

    @GestureState private var isActivelyDragging: Bool = false

    @State private var isDragging: Bool = false
    @State private var isHovering: Bool = false
    @State private var currentDetent: SplitDetent

    var axis: Axis
    var detents: Set<SplitDetent>
    @Binding var selection: SplitDetent

    var primary: Primary
    var secondary: Secondary
    var separator: Separator

    public init(
        _ axis: Axis,
        detents: Set<SplitDetent>,
        selection: Binding<SplitDetent>,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary,
        @ViewBuilder separator: () -> Separator
    ) {
        _selection = selection
        self.axis = axis
        self.detents = detents
        self.primary = primary()
        self.secondary = secondary()
        self.separator = separator()
        _currentDetent = .init(initialValue: selection.wrappedValue)
    }

    public init(
        _ axis: Axis,
        detents: Set<SplitDetent>,
        selection: Binding<SplitDetent>,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) where Separator == SplitViewSeparator {
        _selection = selection
        self.axis = axis
        self.detents = detents
        self.primary = primary()
        self.secondary = secondary()
        _currentDetent = .init(initialValue: selection.wrappedValue)
        separator = .init()
    }

    private var Layout: AnyLayout {
        switch axis {
        case .horizontal:
            AnyLayout(HStackLayout(spacing: 0))
        case .vertical:
            AnyLayout(VStackLayout(spacing: 0))
        }
    }

    public var body: some View {
        GeometryReader { proxy in
            let maxValue = axis == .horizontal ? proxy.size.width : proxy.size.height
            let context = SplitDetent.Context(environment: environment, maxDetentValue: maxValue)

            Layout {
                primary
                    .modifier(SplitDetentModifier(
                        axis: axis,
                        proxy: proxy,
                        detent: isDragging ? currentDetent : selection)
                    )
                    .zIndex(1)
                ResizeView(context: context)
                secondary
                    .zIndex(1)
            }
            .environment(\.splitViewDragging, isDragging)
            .environment(\.splitViewAxis, axis)
            .animation(.bouncy, value: isDragging)
            .onChange(of: detents, initial: true) { _, newValue in
                guard !newValue.contains(selection) else { return }
                let length = selection.id.length(in: context)
                let fraction = length / context.maxDetentValue

                withAnimation(.bouncy) {
                    selection = targetDetent(
                        predictedFraction: fraction,
                        detents: newValue,
                        context: context
                    ) ?? selection
                    currentDetent = selection
                }
            }
        }
        .onChange(of: selection) { _, newValue in
            withAnimation(nil) {
                currentDetent = newValue
            }
        }
    }

    @ViewBuilder
    private func ResizeView(context: SplitDetent.Context) -> some View {
        let length = selection.id.length(in: context)

        separator
            .contentShape(.rect.inset(by: -5))
            .zIndex(1000)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .updating($isActivelyDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                        }

                        let translation = axis == .horizontal ? value.translation.width : value.translation.height
                        let currentLength = length + translation
                        let effectiveLength = elasticLength(
                            dragLocation: currentLength,
                            context: context
                        )

                        currentDetent = .fraction(effectiveLength / context.maxDetentValue)
                    }
                    .onEnded { value in
                        isDragging = false

                        if resizeBehavior.isContinuous {
                            // Use current position without prediction, but clamp to min/max bounds
                            let currentFraction = currentDetent.id.length(in: context) / context.maxDetentValue
                            let clampedFraction = clampedFraction(currentFraction, context: context)
                            let detent = SplitDetent.fraction(clampedFraction)

                            withAnimation(.bouncy) {
                                selection = detent
                                currentDetent = detent
                            }
                        } else {
                            // Snap to nearest detent using prediction
                            let predicted = axis == .horizontal
                            ? value.predictedEndLocation.x
                            : value.predictedEndLocation.y
                            let start = axis == .horizontal
                            ? value.startLocation.x
                            : value.startLocation.y

                            let predictedTranslation = predicted - start
                            let predictedLength = length + predictedTranslation
                            let predictedFraction = predictedLength / context.maxDetentValue

                            let target = targetDetent(
                                predictedFraction: predictedFraction,
                                detents: detents,
                                context: context
                            ) ?? selection

                            withAnimation(.bouncy) {
                                selection = target
                                currentDetent = target
                            }
                        }
                    }
                , isEnabled: isDragEnabled
            )
            .onChange(of: isActivelyDragging) { _, isActive in
                // When gesture is cancelled, @GestureState resets to false
                // This gives us a chance to reset. Often caused by system
                // gestures.
                if !isActive && isDragging {
                    isDragging = false
                    currentDetent = selection
                }
            }
#if os(macOS)
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

    private var isDragEnabled: Bool {
        detents.count > 1
    }

    private func targetDetent(
        predictedFraction: CGFloat,
        detents: Set<SplitDetent>,
        context: SplitDetent.Context
    ) -> SplitDetent? {
        detents.min {
            let fraction1 = $0.id.length(in: context) / context.maxDetentValue
            let fraction2 = $1.id.length(in: context) / context.maxDetentValue
            return abs(fraction1 - predictedFraction) < abs(fraction2 - predictedFraction)
        }
    }

    private func clampedFraction(
        _ fraction: CGFloat,
        context: SplitDetent.Context
    ) -> CGFloat {
        let detentLengths = detents.map { $0.id.length(in: context) }
        guard let minDetent = detentLengths.min(),
              let maxDetent = detentLengths.max() else {
            return fraction
        }

        let minFraction = minDetent / context.maxDetentValue
        let maxFraction = maxDetent / context.maxDetentValue
        return max(minFraction, min(maxFraction, fraction))
    }

    private func elasticLength(
        dragLocation: CGFloat,
        context: SplitDetent.Context
    ) -> CGFloat {
        // Get min and max detent lengths
        let detentLengths = detents.map { $0.id.length(in: context) }

        guard let minDetent = detentLengths.min(),
              let maxDetent = detentLengths.max() else {
            return dragLocation
        }

        var shouldDisableElasticity: Bool {
            switch elasticBehaviour {
            case .automatic:
                !elasticBehaviour.isEnabled || isReduceMotionEnabled
            case .always: false
            case .never: true
            }
        }

        if shouldDisableElasticity {
            return max(minDetent, min(maxDetent, dragLocation))
        }

        // If within bounds, return as-is
        if dragLocation >= minDetent && dragLocation <= maxDetent {
            return dragLocation
        }

        // Apply rubber-banding when beyond bounds
        let resistance: CGFloat = 0.5

        if dragLocation < minDetent {
            // Dragging above the minimum detent
            let distance = minDetent - dragLocation
            let rubberBand = (1.0 - (1.0 / ((distance * resistance / minDetent) + 1.0))) * minDetent
            return minDetent - rubberBand
        } else {
            // Dragging below the maximum detent
            let distance = dragLocation - maxDetent
            let dimension = context.maxDetentValue - maxDetent
            let rubberBand = (1.0 - (1.0 / ((distance * resistance / dimension) + 1.0))) * dimension
            return maxDetent + rubberBand
        }
    }
}

private struct Preview: View {
    @State var selection: SplitDetent = .medium

    var body: some View {
        SplitView(.vertical, detents: [.small, .large], selection: $selection) {
            Color.green
                .overlay(alignment: .top) { Text("Top").padding(25) }
                .overlay(alignment: .bottom) { Text("Bottom").padding(25) }
        } secondary: {
            Color.blue
                .overlay(alignment: .top) { Text("Top").padding(25) }
                .overlay(alignment: .bottom) { Text("Bottom").padding(25) }
        } separator: {
            Rectangle()
                .foregroundStyle(.bar)
                .frame(height: 30)
                .overlay(alignment: .trailing) {
                    Image(systemName: "line.3.horizontal")
                        .fontWeight(.heavy)
                        .foregroundStyle(.quaternary)
                        .padding(.trailing, 10)
                }
        }
        .frame(maxWidth: .infinity)
        .background(.quinary)
        .ignoresSafeArea()
        .overlay {
            Picker("", selection: $selection) {
                Text("Small").tag(SplitDetent.small)
                Text("Medium").tag(SplitDetent.medium)
                Text("Large").tag(SplitDetent.large)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .scenePadding()
            .offset(y: 80)
        }
    }
}

#Preview {
    Preview()
}

