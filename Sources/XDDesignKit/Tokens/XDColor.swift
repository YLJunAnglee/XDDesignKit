import UIKit

public enum XDColor {
    @MainActor
    public static var brandPrimary: UIColor { dynamic(.brandPrimary) }
    @MainActor
    public static var brandPrimaryHighlighted: UIColor { dynamic(.brandPrimaryHighlighted) }
    @MainActor
    public static var brandPrimaryDisabled: UIColor { dynamic(.brandPrimaryDisabled) }

    @MainActor
    public static var textPrimary: UIColor { dynamic(.textPrimary) }
    @MainActor
    public static var textSecondary: UIColor { dynamic(.textSecondary) }
    @MainActor
    public static var textTertiary: UIColor { dynamic(.textTertiary) }
    @MainActor
    public static var textInverse: UIColor { dynamic(.textInverse) }

    @MainActor
    public static var backgroundPrimary: UIColor { dynamic(.backgroundPrimary) }
    @MainActor
    public static var backgroundSecondary: UIColor { dynamic(.backgroundSecondary) }
    @MainActor
    public static var backgroundDisabled: UIColor { dynamic(.backgroundDisabled) }

    @MainActor
    public static var borderPrimary: UIColor { dynamic(.borderPrimary) }
    @MainActor
    public static var borderStrong: UIColor { dynamic(.borderStrong) }

    @MainActor
    public static func color(
        _ token: XDColorToken,
        compatibleWith traitCollection: UITraitCollection
    ) -> UIColor {
        XDThemeManager.shared.color(for: token, compatibleWith: traitCollection)
    }

    @MainActor
    public static func dynamic(_ token: XDColorToken) -> UIColor {
        XDThemeManager.shared.globalContext.dynamicColor(token)
    }
}

public extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(hex & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
