import Foundation

public struct XDComponentState: OptionSet, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let normal = XDComponentState([])
    public static let highlighted = XDComponentState(rawValue: 1 << 0)
    public static let selected = XDComponentState(rawValue: 1 << 1)
    public static let disabled = XDComponentState(rawValue: 1 << 2)
    public static let loading = XDComponentState(rawValue: 1 << 3)
    public static let focused = XDComponentState(rawValue: 1 << 4)
    public static let error = XDComponentState(rawValue: 1 << 5)

    public var isNormal: Bool {
        isEmpty
    }
}
