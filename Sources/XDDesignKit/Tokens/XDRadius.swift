import UIKit

public enum XDRadius {
    @MainActor
    public static func value(_ token: XDRadiusToken) -> CGFloat {
        value(token, theme: XDThemeManager.shared.currentTheme)
    }

    public static func value(_ token: XDRadiusToken, theme: XDTheme) -> CGFloat {
        theme.metrics.radius(for: token)
    }

    @MainActor public static var xs: CGFloat { value(.xs) }
    @MainActor public static var sm: CGFloat { value(.sm) }
    @MainActor public static var md: CGFloat { value(.md) }
    @MainActor public static var lg: CGFloat { value(.lg) }
    @MainActor public static var pill: CGFloat { value(.pill) }
}
