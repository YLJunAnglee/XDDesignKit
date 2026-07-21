import UIKit

public enum XDBorder {
    @MainActor
    public static func width(_ token: XDBorderToken) -> CGFloat {
        width(token, theme: XDThemeManager.shared.currentTheme)
    }

    public static func width(_ token: XDBorderToken, theme: XDTheme) -> CGFloat {
        theme.metrics.borderWidth(for: token)
    }

    @MainActor public static var hairline: CGFloat { width(.hairline) }
    @MainActor public static var thin: CGFloat { width(.thin) }
    @MainActor public static var regular: CGFloat { width(.regular) }
    @MainActor public static var strong: CGFloat { width(.strong) }
}
