import Foundation

/// Theme configuration grouped by component, so generic metrics do not become a catch-all store.
public struct XDThemeComponents: Sendable {
    public let button: XDButtonTheme
    public let alert: XDAlertTheme
    public let bottomSheet: XDBottomSheetTheme
    public let toggle: XDToggleTheme
    public let snackBar: XDSnackBarTheme

    public init(
        button: XDButtonTheme = .default,
        alert: XDAlertTheme = .default,
        bottomSheet: XDBottomSheetTheme = .default,
        toggle: XDToggleTheme = .default,
        snackBar: XDSnackBarTheme = .default
    ) {
        self.button = button
        self.alert = alert
        self.bottomSheet = bottomSheet
        self.toggle = toggle
        self.snackBar = snackBar
    }

    public func merging(
        button: XDButtonTheme? = nil,
        alert: XDAlertTheme? = nil,
        bottomSheet: XDBottomSheetTheme? = nil,
        toggle: XDToggleTheme? = nil,
        snackBar: XDSnackBarTheme? = nil
    ) -> XDThemeComponents {
        XDThemeComponents(
            button: button ?? self.button,
            alert: alert ?? self.alert,
            bottomSheet: bottomSheet ?? self.bottomSheet,
            toggle: toggle ?? self.toggle,
            snackBar: snackBar ?? self.snackBar
        )
    }

    func validationErrors(requireCompleteDefinition: Bool) -> [String] {
        button.validationErrors(requireCompleteDefinition: requireCompleteDefinition)
            + alert.validationErrors()
            + toggle.validationErrors()
            + snackBar.validationErrors()
    }
}

public extension XDThemeComponents {
    static let `default` = XDThemeComponents()
}
