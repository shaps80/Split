import SwiftUI

internal extension SplitDetent {
    enum ID: Hashable, CustomReflectable, Sendable {
        case small
        case medium
        case large
        case fraction(Fraction)
        case length(Length)
        case custom(CustomSplitDetentWrapper)

        func length(in context: Context) -> CGFloat {
            switch self {
            case .small:
                return context.maxDetentValue * max(0, min(1, context.verticalSizeClass == .compact ? 0.4 : 0.25))
            case .medium:
                return context.maxDetentValue * max(0, min(1, 0.5))
            case .large:
                return context.maxDetentValue * max(0, min(1, context.verticalSizeClass == .compact ? 0.6 : 0.75))
            case let .fraction(value):
                return context.maxDetentValue * max(0, min(1, value.fraction))
            case let .length(value):
                return max(0, min(context.maxDetentValue, value.length))
            case let .custom(value):
                return value.base.length(in: context) ?? context.maxDetentValue
            }
        }

        var customMirror: Mirror {
            switch self {
            case .small:
                Mirror(reflecting: Small.self)
            case .medium:
                Mirror(reflecting: Medium.self)
            case .large:
                Mirror(reflecting: Large.self)
            case let .fraction(value):
                Mirror(reflecting: value)
            case let .length(value):
                Mirror(reflecting: value)
            case let .custom(value):
                Mirror(reflecting: value)
            }
        }

        struct Small: Hashable, Sendable, CustomStringConvertible {
            var description: String { String(describing: self) }
        }

        struct Medium: Hashable, Sendable, CustomStringConvertible {
            var description: String { String(describing: self) }
        }

        struct Large: Hashable, Sendable, CustomStringConvertible {
            var description: String { String(describing: self) }
        }

        struct Fraction: Hashable, Sendable, CustomStringConvertible {
            var fraction: CGFloat

            init(fraction: CGFloat) {
                self.fraction = max(0, min(1, fraction))
            }

            var description: String {
                "\(String(describing: type(of: self))) \(fraction)"
            }
        }

        struct Length: Hashable, Sendable, CustomStringConvertible {
            var length: CGFloat

            var description: String {
                "\(String(describing: type(of: self))) \(length)"
            }
        }
    }
}

public extension SplitDetent {
    static func length(_ length: CGFloat) -> Self {
        .init(.length(.init(length: length)))
    }
}

public extension SplitDetent {
    static var small: Self {
        .init(.small)
    }

    static var medium: Self {
        .init(.medium)
    }

    static var large: Self {
        .init(.large)
    }

    static func fraction(_ fraction: CGFloat) -> Self {
        .init(.fraction(.init(fraction: fraction)))
    }
}

internal extension SplitDetent {
    struct CustomSplitDetentWrapper: Hashable, @unchecked Sendable {
        let base: any CustomSplitDetent.Type

        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(base))
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            ObjectIdentifier(lhs.base) == ObjectIdentifier(rhs.base)
        }
    }
}
