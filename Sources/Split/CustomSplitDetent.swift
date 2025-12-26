import SwiftUI

public protocol CustomSplitDetent {
    static func length(in context: Context) -> CGFloat?
}

extension CustomSplitDetent {
    public typealias Context = SplitDetent.Context
}

public extension SplitDetent {
    static func custom<D>(_ type: D.Type) -> SplitDetent where D: CustomSplitDetent {
        .init(.custom(.init(base: type)))
    }
}
