import UIKit

/// Immutable UIKit colors are captured as a theme snapshot. The wrapper is
/// audited as sendable so a locked `XDThemeContext` can resolve dynamic colors.
public struct XDThemeColor: @unchecked Sendable {
    public let light: UIColor
    public let dark: UIColor
    public let lightHighContrast: UIColor?
    public let darkHighContrast: UIColor?

    public init(
        light: UIColor,
        dark: UIColor,
        lightHighContrast: UIColor? = nil,
        darkHighContrast: UIColor? = nil
    ) {
        self.light = light
        self.dark = dark
        self.lightHighContrast = lightHighContrast
        self.darkHighContrast = darkHighContrast
    }

    public init(_ color: UIColor) {
        self.light = color
        self.dark = color
        self.lightHighContrast = nil
        self.darkHighContrast = nil
    }

    public func resolved(compatibleWith traitCollection: UITraitCollection) -> UIColor {
        let isDark = traitCollection.userInterfaceStyle == .dark
        if traitCollection.accessibilityContrast == .high {
            return isDark ? (darkHighContrast ?? dark) : (lightHighContrast ?? light)
        }
        return isDark ? dark : light
    }
}
