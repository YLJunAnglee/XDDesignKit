import UIKit

public struct XDButtonMetricToken: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { precondition(!rawValue.isEmpty); self.rawValue = rawValue }
    public static let large = XDButtonMetricToken(rawValue: "large")
    public static let medium = XDButtonMetricToken(rawValue: "medium")
    public static let small = XDButtonMetricToken(rawValue: "small")
    public static let allCases: [XDButtonMetricToken] = [.large, .medium, .small]
}

public struct XDButtonMetric: Sendable {
    /// Minimum visual height. The button may grow for accessibility text sizes.
    public let height: CGFloat
    public let horizontalPadding: CGFloat
    public let verticalPadding: CGFloat
    public let iconSize: CGFloat
    public let contentSpacing: CGFloat
    /// Top and bottom padding used only when the icon is above or below the title.
    public let stackedContentPadding: CGFloat
    public let fontToken: XDFontToken
    public let radiusToken: XDRadiusToken

    public init(
        height: CGFloat,
        horizontalPadding: CGFloat,
        verticalPadding: CGFloat = 0,
        iconSize: CGFloat = 20,
        contentSpacing: CGFloat = 8,
        stackedContentPadding: CGFloat = 12,
        fontToken: XDFontToken,
        radiusToken: XDRadiusToken
    ) {
        self.height = height
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.iconSize = iconSize
        self.contentSpacing = contentSpacing
        self.stackedContentPadding = stackedContentPadding
        self.fontToken = fontToken
        self.radiusToken = radiusToken
    }
}

/// Semantic colors for one visual state. A nil background or border means clear/none.
public struct XDButtonStateAppearance: Sendable {
    public let background: XDButtonBackground
    public let titleToken: XDColorToken
    public let iconToken: XDColorToken
    public let borderToken: XDColorToken?
    public let borderWidthToken: XDBorderToken?

    public var backgroundToken: XDColorToken? {
        if case let .solid(token) = background.storage { return token }
        return nil
    }

    public init(
        backgroundToken: XDColorToken?,
        titleToken: XDColorToken,
        iconToken: XDColorToken? = nil,
        borderToken: XDColorToken? = nil,
        borderWidthToken: XDBorderToken? = nil
    ) {
        self.background = backgroundToken.map(XDButtonBackground.solid) ?? .clear
        self.titleToken = titleToken
        self.iconToken = iconToken ?? titleToken
        self.borderToken = borderToken
        self.borderWidthToken = borderToken == nil ? nil : (borderWidthToken ?? .regular)
    }

    public init(
        background: XDButtonBackground,
        titleToken: XDColorToken,
        iconToken: XDColorToken? = nil,
        borderToken: XDColorToken? = nil,
        borderWidthToken: XDBorderToken? = nil
    ) {
        self.background = background
        self.titleToken = titleToken
        self.iconToken = iconToken ?? titleToken
        self.borderToken = borderToken
        self.borderWidthToken = borderToken == nil ? nil : (borderWidthToken ?? .regular)
    }
}

/// Complete state table for a button style.
public struct XDButtonStyleAppearance: Sendable {
    public let normal: XDButtonStateAppearance
    public let highlighted: XDButtonStateAppearance
    public let selected: XDButtonStateAppearance
    public let disabled: XDButtonStateAppearance

    public init(
        normal: XDButtonStateAppearance,
        highlighted: XDButtonStateAppearance,
        selected: XDButtonStateAppearance? = nil,
        disabled: XDButtonStateAppearance
    ) {
        self.normal = normal
        self.highlighted = highlighted
        self.selected = selected ?? highlighted
        self.disabled = disabled
    }

    func appearance(for state: XDComponentState) -> XDButtonStateAppearance {
        if state.contains(.disabled) { return disabled }
        if state.contains(.highlighted) { return highlighted }
        if state.contains(.selected) { return selected }
        return normal
    }

    var allAppearances: [XDButtonStateAppearance] {
        [normal, highlighted, selected, disabled]
    }
}

/// Button-only metrics and appearance state tables.
public struct XDButtonTheme: Sendable {
    private let metrics: [XDButtonMetricToken: XDButtonMetric]
    private let appearances: [XDButtonStyle: XDButtonStyleAppearance]
    private let componentColors: [XDColorToken: XDThemeColor]
    public let minimumHitTargetSize: CGSize

    public init(
        metrics: [XDButtonMetricToken: XDButtonMetric],
        appearances: [XDButtonStyle: XDButtonStyleAppearance],
        componentColors: [XDColorToken: XDThemeColor] = [:],
        minimumHitTargetSize: CGSize = CGSize(width: 44, height: 44)
    ) {
        self.metrics = metrics
        self.appearances = appearances
        self.componentColors = componentColors
        self.minimumHitTargetSize = minimumHitTargetSize
    }

    public func metric(for token: XDButtonMetricToken) -> XDButtonMetric {
        metrics[token]
            ?? Self.default.metrics[token]
            ?? Self.default.metrics[.large]!
    }

    public func appearance(for style: XDButtonStyle, state: XDComponentState) -> XDButtonStateAppearance {
        (appearances[style] ?? Self.default.appearances[.primary]!).appearance(for: state)
    }

    func color(for token: XDColorToken, resolver: XDThemeResolver) -> UIColor {
        componentColors[token]?.resolved(compatibleWith: resolver.traitCollection) ?? resolver.color(token)
    }

    public func merging(
        metrics: [XDButtonMetricToken: XDButtonMetric] = [:],
        appearances: [XDButtonStyle: XDButtonStyleAppearance] = [:],
        componentColors: [XDColorToken: XDThemeColor] = [:],
        minimumHitTargetSize: CGSize? = nil
    ) -> XDButtonTheme {
        XDButtonTheme(
            metrics: self.metrics.merging(metrics, uniquingKeysWith: { _, new in new }),
            appearances: self.appearances.merging(appearances, uniquingKeysWith: { _, new in new }),
            componentColors: self.componentColors.merging(componentColors, uniquingKeysWith: { _, new in new }),
            minimumHitTargetSize: minimumHitTargetSize ?? self.minimumHitTargetSize
        )
    }

    func validationErrors(requireCompleteDefinition: Bool) -> [String] {
        var errors: [String] = []
        if requireCompleteDefinition {
            if XDButtonMetricToken.allCases.contains(where: { metrics[$0] == nil }) { errors.append("Missing button metrics") }
            if XDButtonStyle.allCases.contains(where: { appearances[$0] == nil }) { errors.append("Missing button appearances") }
        }
        if metrics.values.contains(where: {
            !$0.height.isFinite || $0.height <= 0
                || !$0.horizontalPadding.isFinite || $0.horizontalPadding < 0
                || !$0.verticalPadding.isFinite || $0.verticalPadding < 0
                || !$0.iconSize.isFinite || $0.iconSize <= 0
                || !$0.contentSpacing.isFinite || $0.contentSpacing < 0
                || !$0.stackedContentPadding.isFinite || $0.stackedContentPadding < 0
        }) { errors.append("Button metrics must be finite and valid") }
        if appearances.values
            .flatMap(\.allAppearances)
            .contains(where: { !$0.background.isValid }) {
            errors.append("Button backgrounds must be finite and valid")
        }
        if !minimumHitTargetSize.width.isFinite || minimumHitTargetSize.width <= 0
            || !minimumHitTargetSize.height.isFinite || minimumHitTargetSize.height <= 0 {
            errors.append("Button minimum hit target must be finite and positive")
        }
        return errors
    }
}

public extension XDButtonTheme {
    static let `default`: XDButtonTheme = {
        let fixedDark = XDColorToken(rawValue: "button.fixed.dark")
        let fixedDarkHighlighted = XDColorToken(rawValue: "button.fixed.dark.highlighted")
        let fixedLight = XDColorToken(rawValue: "button.fixed.light")
        let fixedLightHighlighted = XDColorToken(rawValue: "button.fixed.light.highlighted")
        let fixedDisabledBackground = XDColorToken(rawValue: "button.fixed.disabled.background")
        let fixedDisabledForeground = XDColorToken(rawValue: "button.fixed.disabled.foreground")
        let fixedDisabledBorder = XDColorToken(rawValue: "button.fixed.disabled.border")

        let primary = XDButtonStyleAppearance(
            normal: .init(backgroundToken: fixedDark, titleToken: fixedLight),
            highlighted: .init(backgroundToken: fixedDarkHighlighted, titleToken: fixedLight),
            disabled: .init(backgroundToken: fixedDisabledBackground, titleToken: fixedDisabledForeground)
        )
        let brand = XDButtonStyleAppearance(
            normal: .init(backgroundToken: .brandPrimary, titleToken: .textInverse),
            highlighted: .init(backgroundToken: .brandPrimaryHighlighted, titleToken: .textInverse),
            disabled: .init(backgroundToken: .brandPrimaryDisabled, titleToken: .textInverse)
        )
        let secondary = XDButtonStyleAppearance(
            normal: .init(backgroundToken: .backgroundSecondary, titleToken: .textPrimary, borderToken: .borderPrimary),
            highlighted: .init(backgroundToken: .backgroundHighlighted, titleToken: .textPrimary, borderToken: .borderPrimary),
            disabled: .init(backgroundToken: .backgroundDisabled, titleToken: .textTertiary, borderToken: .borderPrimary)
        )
        let outline = XDButtonStyleAppearance(
            normal: .init(backgroundToken: fixedLight, titleToken: fixedDark, borderToken: fixedDark, borderWidthToken: .hairline),
            highlighted: .init(backgroundToken: fixedLightHighlighted, titleToken: fixedDark, borderToken: fixedDark, borderWidthToken: .hairline),
            disabled: .init(backgroundToken: fixedDisabledBackground, titleToken: fixedDisabledForeground, borderToken: fixedDisabledBorder, borderWidthToken: .hairline)
        )
        let text = XDButtonStyleAppearance(
            normal: .init(backgroundToken: nil, titleToken: .brandPrimary),
            highlighted: .init(backgroundToken: .brandPrimarySubtle, titleToken: .brandPrimary),
            disabled: .init(backgroundToken: nil, titleToken: .textTertiary)
        )
        let gradient = XDButtonStyleAppearance(
            normal: .init(
                background: .gradient(.init(colorTokens: [.brandPrimary, .brandPrimaryHighlighted])),
                titleToken: .textInverse
            ),
            highlighted: .init(
                background: .gradient(.init(colorTokens: [.brandPrimaryHighlighted, .brandPrimary])),
                titleToken: .textInverse
            ),
            disabled: .init(backgroundToken: .brandPrimaryDisabled, titleToken: .textInverse)
        )

        return XDButtonTheme(
            metrics: [
                .large: XDButtonMetric(height: 48, horizontalPadding: 20, stackedContentPadding: 12, fontToken: .bodyLarge, radiusToken: .md),
                .medium: XDButtonMetric(height: 40, horizontalPadding: 16, stackedContentPadding: 10, fontToken: .bodyMedium, radiusToken: .md),
                .small: XDButtonMetric(height: 32, horizontalPadding: 12, stackedContentPadding: 8, fontToken: .captionMedium, radiusToken: .sm)
            ],
            appearances: [
                .primary: primary,
                .brand: brand,
                .secondary: secondary,
                .outline: outline,
                .text: text,
                .gradient: gradient
            ],
            componentColors: [
                fixedDark: XDThemeColor(UIColor(hex: 0x222222)),
                fixedDarkHighlighted: XDThemeColor(UIColor(hex: 0x333333)),
                fixedLight: XDThemeColor(.white),
                fixedLightHighlighted: XDThemeColor(UIColor(hex: 0xF7F7F7)),
                fixedDisabledBackground: XDThemeColor(UIColor(hex: 0xF2F2F2)),
                fixedDisabledForeground: XDThemeColor(UIColor(hex: 0x999999)),
                fixedDisabledBorder: XDThemeColor(UIColor(hex: 0xD0D0D0))
            ]
        )
    }()
}
