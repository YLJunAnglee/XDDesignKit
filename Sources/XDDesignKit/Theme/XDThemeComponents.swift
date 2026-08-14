import Foundation

/// Theme configuration grouped by component, so generic metrics do not become a catch-all store.
public struct XDThemeComponents: Sendable {
    public let button: XDButtonTheme
    public let alert: XDAlertTheme
    public let bottomSheet: XDBottomSheetTheme
    public let toggle: XDToggleTheme

    public init(
        button: XDButtonTheme = .default,
        alert: XDAlertTheme = .default,
        bottomSheet: XDBottomSheetTheme = .default,
        toggle: XDToggleTheme = .default
    ) {
        self.button = button
        self.alert = alert
        self.bottomSheet = bottomSheet
        self.toggle = toggle
    }

    public func merging(
        button: XDButtonTheme? = nil,
        alert: XDAlertTheme? = nil,
        bottomSheet: XDBottomSheetTheme? = nil,
        toggle: XDToggleTheme? = nil
    ) -> XDThemeComponents {
        XDThemeComponents(
            button: button ?? self.button,
            alert: alert ?? self.alert,
            bottomSheet: bottomSheet ?? self.bottomSheet,
            toggle: toggle ?? self.toggle
        )
    }

    func validationErrors(requireCompleteDefinition: Bool) -> [String] {
        button.validationErrors(requireCompleteDefinition: requireCompleteDefinition)
            + alert.validationErrors()
            + toggle.validationErrors()
    }
}

public extension XDThemeComponents {
    static let `default` = XDThemeComponents()
}
