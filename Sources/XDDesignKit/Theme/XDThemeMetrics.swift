import UIKit

public struct XDRadiusToken: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { precondition(!rawValue.isEmpty); self.rawValue = rawValue }
    public static let xs = XDRadiusToken(rawValue: "xs")
    public static let sm = XDRadiusToken(rawValue: "sm")
    public static let md = XDRadiusToken(rawValue: "md")
    public static let lg = XDRadiusToken(rawValue: "lg")
    public static let pill = XDRadiusToken(rawValue: "pill")
    public static let allCases: [XDRadiusToken] = [.xs, .sm, .md, .lg, .pill]
}

public struct XDSpacingToken: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { precondition(!rawValue.isEmpty); self.rawValue = rawValue }
    public static let xxs = XDSpacingToken(rawValue: "xxs")
    public static let xs = XDSpacingToken(rawValue: "xs")
    public static let sm = XDSpacingToken(rawValue: "sm")
    public static let md = XDSpacingToken(rawValue: "md")
    public static let lg = XDSpacingToken(rawValue: "lg")
    public static let xl = XDSpacingToken(rawValue: "xl")
    public static let allCases: [XDSpacingToken] = [.xxs, .xs, .sm, .md, .lg, .xl]
}

public struct XDBorderToken: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { precondition(!rawValue.isEmpty); self.rawValue = rawValue }
    public static let hairline = XDBorderToken(rawValue: "hairline")
    public static let thin = XDBorderToken(rawValue: "thin")
    public static let regular = XDBorderToken(rawValue: "regular")
    public static let strong = XDBorderToken(rawValue: "strong")
    public static let allCases: [XDBorderToken] = [.hairline, .thin, .regular, .strong]
}

public struct XDOpacityToken: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { precondition(!rawValue.isEmpty); self.rawValue = rawValue }
    public static let subtle = XDOpacityToken(rawValue: "subtle")
    public static let disabled = XDOpacityToken(rawValue: "disabled")
    public static let overlay = XDOpacityToken(rawValue: "overlay")
    public static let allCases: [XDOpacityToken] = [.subtle, .disabled, .overlay]
}

public struct XDShadowToken: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { precondition(!rawValue.isEmpty); self.rawValue = rawValue }
    public static let none = XDShadowToken(rawValue: "none")
    public static let card = XDShadowToken(rawValue: "card")
    public static let floating = XDShadowToken(rawValue: "floating")
    public static let allCases: [XDShadowToken] = [.none, .card, .floating]
}

public struct XDMotionToken: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { precondition(!rawValue.isEmpty); self.rawValue = rawValue }
    public static let instant = XDMotionToken(rawValue: "instant")
    public static let fast = XDMotionToken(rawValue: "fast")
    public static let standard = XDMotionToken(rawValue: "standard")
    public static let emphasized = XDMotionToken(rawValue: "emphasized")
    public static let allCases: [XDMotionToken] = [.instant, .fast, .standard, .emphasized]
}

public enum XDMotionCurve: Sendable {
    case linear
    case easeIn
    case easeOut
    case easeInOut

    public var animationOptions: UIView.AnimationOptions {
        switch self {
        case .linear: return .curveLinear
        case .easeIn: return .curveEaseIn
        case .easeOut: return .curveEaseOut
        case .easeInOut: return .curveEaseInOut
        }
    }
}

public struct XDMotionStyle: Sendable {
    public let duration: TimeInterval
    public let curve: XDMotionCurve

    public init(duration: TimeInterval, curve: XDMotionCurve) {
        self.duration = duration
        self.curve = curve
    }
}

public struct XDShadowStyle: Sendable {
    public let colorToken: XDColorToken
    public let offset: CGSize
    public let radius: CGFloat
    public let opacity: Float

    public init(colorToken: XDColorToken, offset: CGSize, radius: CGFloat, opacity: Float) {
        self.colorToken = colorToken
        self.offset = offset
        self.radius = radius
        self.opacity = opacity
    }
}

/// Theme-dependent foundation values. Component-only specifications belong in
/// `XDThemeComponents` rather than this type.
public struct XDThemeMetrics: Sendable {
    public let fontFamily: XDFontFamily
    private let fonts: [XDFontToken: XDFontStyle]
    private let spacings: [XDSpacingToken: CGFloat]
    private let radii: [XDRadiusToken: CGFloat]
    private let borderWidths: [XDBorderToken: CGFloat]
    private let opacities: [XDOpacityToken: CGFloat]
    private let shadows: [XDShadowToken: XDShadowStyle]
    private let motions: [XDMotionToken: XDMotionStyle]

    public init(
        fontFamily: XDFontFamily = .pingFangSC,
        fonts: [XDFontToken: XDFontStyle],
        spacings: [XDSpacingToken: CGFloat],
        radii: [XDRadiusToken: CGFloat],
        borderWidths: [XDBorderToken: CGFloat],
        opacities: [XDOpacityToken: CGFloat],
        shadows: [XDShadowToken: XDShadowStyle],
        motions: [XDMotionToken: XDMotionStyle]
    ) {
        self.fontFamily = fontFamily
        self.fonts = fonts
        self.spacings = spacings
        self.radii = radii
        self.borderWidths = borderWidths
        self.opacities = opacities
        self.shadows = shadows
        self.motions = motions
    }

    /// Returns nil when neither this theme nor the default theme defines the token.
    public func fontStyleIfDefined(for token: XDFontToken) -> XDFontStyle? {
        fonts[token] ?? Self.default.fonts[token]
    }

    /// Resolves a token safely. Unknown custom tokens fall back to body instead of recursing.
    public func fontStyle(for token: XDFontToken) -> XDFontStyle {
        fontStyleIfDefined(for: token) ?? Self.default.fonts[.body]!
    }
    public func radius(for token: XDRadiusToken) -> CGFloat { radii[token] ?? Self.default.radius(for: token) }
    public func spacing(for token: XDSpacingToken) -> CGFloat { spacings[token] ?? Self.default.spacing(for: token) }
    public func borderWidth(for token: XDBorderToken) -> CGFloat { borderWidths[token] ?? Self.default.borderWidth(for: token) }
    public func opacity(for token: XDOpacityToken) -> CGFloat { opacities[token] ?? Self.default.opacity(for: token) }
    public func shadow(for token: XDShadowToken) -> XDShadowStyle { shadows[token] ?? Self.default.shadow(for: token) }
    public func motion(for token: XDMotionToken) -> XDMotionStyle { motions[token] ?? Self.default.motion(for: token) }

    public func merging(
        fontFamily: XDFontFamily? = nil,
        fonts: [XDFontToken: XDFontStyle] = [:],
        spacings: [XDSpacingToken: CGFloat] = [:],
        radii: [XDRadiusToken: CGFloat] = [:],
        borderWidths: [XDBorderToken: CGFloat] = [:],
        opacities: [XDOpacityToken: CGFloat] = [:],
        shadows: [XDShadowToken: XDShadowStyle] = [:],
        motions: [XDMotionToken: XDMotionStyle] = [:]
    ) -> XDThemeMetrics {
        XDThemeMetrics(
            fontFamily: fontFamily ?? self.fontFamily,
            fonts: self.fonts.merging(fonts, uniquingKeysWith: { _, new in new }),
            spacings: self.spacings.merging(spacings, uniquingKeysWith: { _, new in new }),
            radii: self.radii.merging(radii, uniquingKeysWith: { _, new in new }),
            borderWidths: self.borderWidths.merging(borderWidths, uniquingKeysWith: { _, new in new }),
            opacities: self.opacities.merging(opacities, uniquingKeysWith: { _, new in new }),
            shadows: self.shadows.merging(shadows, uniquingKeysWith: { _, new in new }),
            motions: self.motions.merging(motions, uniquingKeysWith: { _, new in new })
        )
    }

    func validationErrors(requireCompleteDefinition: Bool) -> [String] {
        var errors: [String] = []
        if requireCompleteDefinition {
            appendMissing("font", required: XDFontToken.allCases, defined: fonts.keys, to: &errors)
            appendMissing("spacing", required: XDSpacingToken.allCases, defined: spacings.keys, to: &errors)
            appendMissing("radius", required: XDRadiusToken.allCases, defined: radii.keys, to: &errors)
            appendMissing("border", required: XDBorderToken.allCases, defined: borderWidths.keys, to: &errors)
            appendMissing("opacity", required: XDOpacityToken.allCases, defined: opacities.keys, to: &errors)
            appendMissing("shadow", required: XDShadowToken.allCases, defined: shadows.keys, to: &errors)
            appendMissing("motion", required: XDMotionToken.allCases, defined: motions.keys, to: &errors)
        }

        if !fontFamily.isValid { errors.append("Font family names must not be empty") }
        if fonts.values.contains(where: { !$0.pointSize.isFinite || $0.pointSize <= 0 }) { errors.append("Font point sizes must be finite and positive") }
        if fonts.values.contains(where: { $0.fontName.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? false }) { errors.append("Font names must not be empty") }
        if fonts.values.contains(where: { $0.lineHeight.map { !$0.isFinite || $0 <= 0 } ?? false }) { errors.append("Font line heights must be finite and positive") }
        if fonts.values.contains(where: { !$0.letterSpacing.isFinite }) { errors.append("Font letter spacing must be finite") }
        if fonts.values.contains(where: { style in
            style.maximumPointSize.map { !$0.isFinite || $0 < style.pointSize } ?? false
        }) { errors.append("Maximum font sizes must be finite and not smaller than the base size") }
        if fonts.values.contains(where: { $0.scaling == .fixed && $0.maximumPointSize != nil }) {
            errors.append("Fixed fonts must not define a maximum point size")
        }
        if spacings.values.contains(where: { !$0.isFinite || $0 < 0 }) { errors.append("Spacing values must be finite and nonnegative") }
        if radii.values.contains(where: { !$0.isFinite || $0 < 0 }) { errors.append("Radius values must be finite and nonnegative") }
        if borderWidths.values.contains(where: { !$0.isFinite || $0 < 0 }) { errors.append("Border widths must be finite and nonnegative") }
        if opacities.values.contains(where: { !$0.isFinite || $0 < 0 || $0 > 1 }) { errors.append("Opacity values must be finite and between 0 and 1") }
        if shadows.values.contains(where: { !$0.radius.isFinite || $0.radius < 0 || !$0.opacity.isFinite || $0.opacity < 0 || $0.opacity > 1 || !$0.offset.width.isFinite || !$0.offset.height.isFinite }) { errors.append("Shadow values must be finite and valid") }
        if motions.values.contains(where: { !$0.duration.isFinite || $0.duration < 0 }) { errors.append("Motion durations must be finite and nonnegative") }
        return errors
    }
}

private func appendMissing<Token: Hashable, Value>(
    _ name: String,
    required: [Token],
    defined: Dictionary<Token, Value>.Keys,
    to errors: inout [String]
) {
    let definedSet = Set(defined)
    if required.contains(where: { !definedSet.contains($0) }) {
        errors.append("Missing \(name) metrics")
    }
}

public extension XDThemeMetrics {
    static let `default` = XDThemeMetrics(
        fontFamily: .pingFangSC,
        fonts: [
            .title1: XDFontStyle(pointSize: 20, weight: .semibold, textStyle: .title2, lineHeight: 28),
            .title2: XDFontStyle(pointSize: 18, weight: .semibold, textStyle: .title3, lineHeight: 26),
            .title3: XDFontStyle(pointSize: 16, weight: .semibold, textStyle: .headline, lineHeight: 24),
            .bodyLarge: XDFontStyle(pointSize: 16, weight: .regular, textStyle: .body, lineHeight: 24),
            .body: XDFontStyle(pointSize: 14, weight: .regular, textStyle: .body, lineHeight: 22),
            .bodyMedium: XDFontStyle(pointSize: 14, weight: .medium, textStyle: .body, lineHeight: 22),
            .caption: XDFontStyle(pointSize: 12, weight: .regular, textStyle: .caption1, lineHeight: 18),
            .captionMedium: XDFontStyle(pointSize: 12, weight: .medium, textStyle: .caption1, lineHeight: 18)
        ],
        spacings: [.xxs: 4, .xs: 8, .sm: 12, .md: 16, .lg: 24, .xl: 32],
        radii: [.xs: 2, .sm: 4, .md: 8, .lg: 12, .pill: 999],
        // Hairline stores physical pixel count; XDThemeResolver converts it to points.
        borderWidths: [.hairline: 1, .thin: 0.5, .regular: 1, .strong: 2],
        opacities: [.subtle: 0.08, .disabled: 0.4, .overlay: 0.48],
        shadows: [
            .none: XDShadowStyle(colorToken: .shadowPrimary, offset: .zero, radius: 0, opacity: 0),
            .card: XDShadowStyle(colorToken: .shadowPrimary, offset: CGSize(width: 0, height: 2), radius: 8, opacity: 0.12),
            .floating: XDShadowStyle(colorToken: .shadowPrimary, offset: CGSize(width: 0, height: 6), radius: 16, opacity: 0.16)
        ],
        motions: [
            .instant: XDMotionStyle(duration: 0, curve: .linear),
            .fast: XDMotionStyle(duration: 0.15, curve: .easeOut),
            .standard: XDMotionStyle(duration: 0.25, curve: .easeInOut),
            .emphasized: XDMotionStyle(duration: 0.35, curve: .easeInOut)
        ]
    )
}
