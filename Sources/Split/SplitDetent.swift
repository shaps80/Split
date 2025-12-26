import SwiftUI

public struct SplitDetent: Sendable, Hashable {
    internal let id: ID

    internal init(_ id: ID) {
        self.id = id
    }

    @dynamicMemberLookup public struct Context {
        internal var environment: EnvironmentValues
        public var maxDetentValue: CGFloat

        public subscript<T>(dynamicMember keyPath: KeyPath<EnvironmentValues, T>) -> T {
            environment[keyPath: keyPath]
        }
    }
}
