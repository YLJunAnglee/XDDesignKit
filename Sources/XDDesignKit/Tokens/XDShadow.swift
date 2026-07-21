import UIKit

public enum XDShadow {
    @MainActor
    public static func style(_ token: XDShadowToken) -> XDShadowStyle {
        XDThemeManager.shared.currentTheme.metrics.shadow(for: token)
    }

    public static func style(_ token: XDShadowToken, theme: XDTheme) -> XDShadowStyle {
        theme.metrics.shadow(for: token)
    }
}

public extension CALayer {
    /// Apply again from `xdApplyTheme()` because Core Animation stores CGColor.
    @MainActor
    func xdApplyShadow(_ token: XDShadowToken, resolver: XDThemeResolver) {
        let style = resolver.shadow(token)
        shadowColor = resolver.color(style.colorToken).cgColor
        shadowOffset = style.offset
        shadowRadius = style.radius
        shadowOpacity = style.opacity
    }
}
