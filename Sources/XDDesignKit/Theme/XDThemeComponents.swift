import Foundation

/// Theme configuration grouped by component, so generic metrics do not become a catch-all store.
public struct XDThemeComponents: Sendable {
    public let button: XDButtonTheme

    public init(button: XDButtonTheme = .default) {
        self.button = button
    }

    public func merging(button: XDButtonTheme? = nil) -> XDThemeComponents {
        XDThemeComponents(button: button ?? self.button)
    }

    func validationErrors(requireCompleteDefinition: Bool) -> [String] {
        button.validationErrors(requireCompleteDefinition: requireCompleteDefinition)
    }
}

public extension XDThemeComponents {
    static let `default` = XDThemeComponents()
}
