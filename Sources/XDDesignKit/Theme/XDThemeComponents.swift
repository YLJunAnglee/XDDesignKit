import Foundation

/// Theme configuration grouped by component, so generic metrics do not become a catch-all store.
public struct XDThemeComponents: Sendable {
    public let button: XDButtonTheme
    public let alert: XDAlertTheme

    public init(
        button: XDButtonTheme = .default,
        alert: XDAlertTheme = .default
    ) {
        self.button = button
        self.alert = alert
    }

    public func merging(
        button: XDButtonTheme? = nil,
        alert: XDAlertTheme? = nil
    ) -> XDThemeComponents {
        XDThemeComponents(
            button: button ?? self.button,
            alert: alert ?? self.alert
        )
    }

    func validationErrors(requireCompleteDefinition: Bool) -> [String] {
        button.validationErrors(requireCompleteDefinition: requireCompleteDefinition)
            + alert.validationErrors()
    }
}

public extension XDThemeComponents {
    static let `default` = XDThemeComponents()
}
