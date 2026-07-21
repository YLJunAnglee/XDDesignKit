import UIKit

public enum XDFont {
    public static let fixed = XDFixedFontFactory()

    @MainActor
    public static func font(
        _ token: XDFontToken,
        compatibleWith traitCollection: UITraitCollection
    ) -> UIFont {
        font(token, compatibleWith: traitCollection, theme: XDThemeManager.shared.currentTheme)
    }

    public static func font(
        _ token: XDFontToken,
        compatibleWith traitCollection: UITraitCollection,
        theme: XDTheme
    ) -> UIFont {
        theme.metrics.fontStyle(for: token).resolved(
            compatibleWith: traitCollection,
            fontFamily: theme.metrics.fontFamily
        )
    }
}

/// Explicit fixed-size escape hatch for legacy migration and one-off business UI.
public struct XDFixedFontFactory: Sendable {
    public init() {}

    @MainActor
    public func regular(_ pointSize: CGFloat) -> UIFont {
        regular(pointSize, theme: XDThemeManager.shared.currentTheme)
    }

    public func regular(_ pointSize: CGFloat, theme: XDTheme) -> UIFont {
        theme.metrics.fontFamily.font(ofSize: pointSize, weight: .regular)
    }

    @MainActor
    public func medium(_ pointSize: CGFloat) -> UIFont {
        medium(pointSize, theme: XDThemeManager.shared.currentTheme)
    }

    public func medium(_ pointSize: CGFloat, theme: XDTheme) -> UIFont {
        theme.metrics.fontFamily.font(ofSize: pointSize, weight: .medium)
    }

    @MainActor
    public func semibold(_ pointSize: CGFloat) -> UIFont {
        semibold(pointSize, theme: XDThemeManager.shared.currentTheme)
    }

    public func semibold(_ pointSize: CGFloat, theme: XDTheme) -> UIFont {
        theme.metrics.fontFamily.font(ofSize: pointSize, weight: .semibold)
    }
}
