import UIKit

public enum XDOpacity {
    @MainActor
    public static func value(_ token: XDOpacityToken) -> CGFloat {
        value(token, theme: XDThemeManager.shared.currentTheme)
    }

    public static func value(_ token: XDOpacityToken, theme: XDTheme) -> CGFloat {
        theme.metrics.opacity(for: token)
    }

    @MainActor public static var subtle: CGFloat { value(.subtle) }
    @MainActor public static var disabled: CGFloat { value(.disabled) }
    @MainActor public static var overlay: CGFloat { value(.overlay) }
}
