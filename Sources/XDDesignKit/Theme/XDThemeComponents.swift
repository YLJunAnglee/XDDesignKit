import Foundation

/// Theme configuration grouped by component, so generic metrics do not become a catch-all store.
public struct XDThemeComponents: Sendable {
    public let button: XDButtonTheme
    public let alert: XDAlertTheme
    public let bottomSheet: XDBottomSheetTheme

    public init(
        button: XDButtonTheme = .default,
        alert: XDAlertTheme = .default,
        bottomSheet: XDBottomSheetTheme = .default
    ) {
        self.button = button
        self.alert = alert
        self.bottomSheet = bottomSheet
    }

    public func merging(
        button: XDButtonTheme? = nil,
        alert: XDAlertTheme? = nil,
        bottomSheet: XDBottomSheetTheme? = nil
    ) -> XDThemeComponents {
        XDThemeComponents(
            button: button ?? self.button,
            alert: alert ?? self.alert,
            bottomSheet: bottomSheet ?? self.bottomSheet
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
