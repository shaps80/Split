import SwiftUI

public extension EnvironmentValues {
    @Entry internal(set) var splitViewDragging: Bool = false
    @Entry internal(set) var splitViewAxis: Axis = .vertical
}

internal extension EnvironmentValues {
    @Entry var splitViewElasticBehavior: SplitViewElasticBehaviour = .automatic
    @Entry var splitViewDragIndicator: Visibility = .automatic
    @Entry var splitViewResizeBehavior: SplitViewResizeBehavior = .automatic
    @Entry var isDragEnabled: Bool = false
}

public enum SplitViewResizeBehavior: Sendable {
    case automatic
    case continuous
    case magnetic

    public var isContinuous: Bool {
        switch self {
        case .automatic:
#if os(macOS)
            true
#else
            false
#endif
        case .continuous:
            true
        case .magnetic:
            false
        }
    }
}

public enum SplitViewElasticBehaviour: Sendable {
    case automatic
    case always
    case never

    public var isEnabled: Bool {
        switch self {
        case .automatic:
#if os(macOS)
            false
#else
            true
#endif
        case .always:
            true
        case .never:
            false
        }
    }
}

public extension View {
    func splitViewElasticity(_ behaviour: SplitViewElasticBehaviour) -> some View {
        environment(\.splitViewElasticBehavior, behaviour)
    }

    func splitViewDragIndicator(_ visibility: Visibility) -> some View {
        environment(\.splitViewDragIndicator, visibility)
    }

    func splitViewResizing(_ behavior: SplitViewResizeBehavior) -> some View {
        environment(\.splitViewResizeBehavior, behavior)
    }
}
