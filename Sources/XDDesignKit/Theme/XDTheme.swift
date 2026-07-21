import UIKit

/// An immutable, fully resolved theme snapshot.
public struct XDTheme: @unchecked Sendable {
    public let identifier: String
    public let displayName: String
    public let metrics: XDThemeMetrics
    public let components: XDThemeComponents
    private let colors: [XDColorToken: XDThemeColor]

    /// Builds a theme by explicitly composing it over `baseTheme`.
    /// Pass `nil` only for a complete root theme.
    public init(
        identifier: String,
        displayName: String,
        colors: [XDColorToken: XDThemeColor],
        metrics: XDThemeMetrics? = nil,
        components: XDThemeComponents? = nil,
        basedOn baseTheme: XDTheme?
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.colors = (baseTheme?.colors ?? [:]).merging(colors, uniquingKeysWith: { _, new in new })
        self.metrics = metrics ?? baseTheme?.metrics ?? .default
        self.components = components ?? baseTheme?.components ?? .default
    }

    public func color(
        for token: XDColorToken,
        compatibleWith traitCollection: UITraitCollection
    ) -> UIColor {
        guard let color = colors[token] else {
            assertionFailure("Theme \(identifier) does not define color token \(token.rawValue)")
            return .clear
        }
        return color.resolved(compatibleWith: traitCollection)
    }

    public func validationResult(requireCompleteDefinition: Bool = true) -> XDThemeValidationResult {
        var errors: [String] = []
        if identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Theme identifier must not be empty")
        }
        if displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Theme display name must not be empty")
        }
        errors.append(contentsOf: metrics.validationErrors(requireCompleteDefinition: requireCompleteDefinition))
        errors.append(contentsOf: components.validationErrors(requireCompleteDefinition: requireCompleteDefinition))

        if requireCompleteDefinition {
            let missingColors = XDColorToken.allCases.filter { colors[$0] == nil }
            if !missingColors.isEmpty {
                errors.append("Missing color tokens: \(missingColors.map(\.rawValue))")
            }
        }
        return XDThemeValidationResult(errors: errors)
    }
}

public extension XDTheme {
    static let defaultTheme: XDTheme = {
        let theme = XDTheme(
            identifier: "xd.default",
            displayName: "Default",
            colors: [
                .brandPrimary: XDThemeColor(light: UIColor(hex: 0xFF542A), dark: UIColor(hex: 0xFF7A54)),
                .brandPrimaryHighlighted: XDThemeColor(light: UIColor(hex: 0xE84924), dark: UIColor(hex: 0xFF663A)),
                .brandPrimaryDisabled: XDThemeColor(light: UIColor(hex: 0xFFCBBE), dark: UIColor(hex: 0x6F3A2C)),
                .brandPrimarySubtle: XDThemeColor(light: UIColor(hex: 0xFFF3EF), dark: UIColor(hex: 0x34221C)),
                .textPrimary: XDThemeColor(light: UIColor(hex: 0x222222), dark: UIColor(hex: 0xF2F3F5)),
                .textSecondary: XDThemeColor(light: UIColor(hex: 0x666666), dark: UIColor(hex: 0xC9CDD4)),
                .textTertiary: XDThemeColor(light: UIColor(hex: 0x999999), dark: UIColor(hex: 0x86909C)),
                .textInverse: XDThemeColor(light: .white, dark: UIColor(hex: 0x111214)),
                .backgroundPrimary: XDThemeColor(light: .white, dark: UIColor(hex: 0x17191C)),
                .backgroundSecondary: XDThemeColor(light: UIColor(hex: 0xF7F8FA), dark: UIColor(hex: 0x24272D)),
                .backgroundHighlighted: XDThemeColor(light: UIColor(hex: 0xECEEF2), dark: UIColor(hex: 0x2F343C)),
                .backgroundDisabled: XDThemeColor(light: UIColor(hex: 0xF2F3F5), dark: UIColor(hex: 0x2B2F36)),
                .borderPrimary: XDThemeColor(light: UIColor(hex: 0xE5E6EB), dark: UIColor(hex: 0x343A43)),
                .borderStrong: XDThemeColor(light: UIColor(hex: 0xD0D3D9), dark: UIColor(hex: 0x4E5969)),
                .shadowPrimary: XDThemeColor(light: .black, dark: .black)
            ],
            metrics: .default,
            components: .default,
            basedOn: nil
        )
        precondition(theme.validationResult().isValid, "XDTheme.defaultTheme must be complete")
        return theme
    }()

    static let blueTheme = XDTheme(
        identifier: "xd.blue",
        displayName: "Blue",
        colors: [
            .brandPrimary: XDThemeColor(light: UIColor(hex: 0x1677FF), dark: UIColor(hex: 0x65A6FF)),
            .brandPrimaryHighlighted: XDThemeColor(light: UIColor(hex: 0x0958D9), dark: UIColor(hex: 0x3C89F7)),
            .brandPrimaryDisabled: XDThemeColor(light: UIColor(hex: 0xBBD8FF), dark: UIColor(hex: 0x244A75)),
            .brandPrimarySubtle: XDThemeColor(light: UIColor(hex: 0xEAF3FF), dark: UIColor(hex: 0x1D314A))
        ],
        basedOn: .defaultTheme
    )
}
