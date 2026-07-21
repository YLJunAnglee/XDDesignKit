import UIKit

public enum XDSpacing {
    @MainActor
    public static func value(_ token: XDSpacingToken) -> CGFloat {
        value(token, theme: XDThemeManager.shared.currentTheme)
    }

    public static func value(_ token: XDSpacingToken, theme: XDTheme) -> CGFloat {
        theme.metrics.spacing(for: token)
    }

    @MainActor public static var xxs: CGFloat { value(.xxs) }
    @MainActor public static var xs: CGFloat { value(.xs) }
    @MainActor public static var sm: CGFloat { value(.sm) }
    @MainActor public static var md: CGFloat { value(.md) }
    @MainActor public static var lg: CGFloat { value(.lg) }
    @MainActor public static var xl: CGFloat { value(.xl) }
}
