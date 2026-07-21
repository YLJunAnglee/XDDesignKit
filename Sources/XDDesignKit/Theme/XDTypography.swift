import UIKit

public struct XDFontToken: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        precondition(!rawValue.isEmpty, "A font token name must not be empty")
        self.rawValue = rawValue
    }

    public static let title1 = XDFontToken(rawValue: "title1")
    public static let title2 = XDFontToken(rawValue: "title2")
    public static let title3 = XDFontToken(rawValue: "title3")
    public static let bodyLarge = XDFontToken(rawValue: "body.large")
    public static let body = XDFontToken(rawValue: "body")
    public static let bodyMedium = XDFontToken(rawValue: "body.medium")
    public static let caption = XDFontToken(rawValue: "caption")
    public static let captionMedium = XDFontToken(rawValue: "caption.medium")

    public static let allCases: [XDFontToken] = [
        .title1, .title2, .title3, .bodyLarge, .body, .bodyMedium, .caption, .captionMedium
    ]
}

/// Immutable font-face mapping used by a theme.
public struct XDFontFamily: Sendable {
    public let regularName: String?
    public let mediumName: String?
    public let semiboldName: String?

    public init(
        regularName: String?,
        mediumName: String?,
        semiboldName: String?
    ) {
        self.regularName = regularName
        self.mediumName = mediumName
        self.semiboldName = semiboldName
    }

    public func font(ofSize pointSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        precondition(pointSize.isFinite && pointSize > 0, "Font point size must be finite and positive")
        let name: String?
        switch weight {
        case .regular: name = regularName
        case .medium: name = mediumName
        case .semibold: name = semiboldName
        default: name = nil
        }
        return name.flatMap { UIFont(name: $0, size: pointSize) }
            ?? UIFont.systemFont(ofSize: pointSize, weight: weight)
    }

    var isValid: Bool {
        [regularName, mediumName, semiboldName]
            .compactMap { $0 }
            .allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

public extension XDFontFamily {
    static let pingFangSC = XDFontFamily(
        regularName: "PingFangSC-Regular",
        mediumName: "PingFangSC-Medium",
        semiboldName: "PingFangSC-Semibold"
    )

    static let system = XDFontFamily(
        regularName: nil,
        mediumName: nil,
        semiboldName: nil
    )
}

public enum XDFontScaling: Equatable, Sendable {
    case fixed
    case dynamic
}

/// Semantic typography including metrics needed by attributed text.
public struct XDFontStyle: Sendable {
    public let pointSize: CGFloat
    public let weight: UIFont.Weight
    public let textStyle: UIFont.TextStyle
    /// Optional one-off face override. The theme's font family remains the fallback.
    public let fontName: String?
    public let lineHeight: CGFloat?
    public let letterSpacing: CGFloat
    public let maximumPointSize: CGFloat?
    public let scaling: XDFontScaling

    public init(
        pointSize: CGFloat,
        weight: UIFont.Weight,
        textStyle: UIFont.TextStyle,
        fontName: String? = nil,
        lineHeight: CGFloat? = nil,
        letterSpacing: CGFloat = 0,
        maximumPointSize: CGFloat? = nil,
        scaling: XDFontScaling = .dynamic
    ) {
        self.pointSize = pointSize
        self.weight = weight
        self.textStyle = textStyle
        self.fontName = fontName
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
        self.maximumPointSize = maximumPointSize
        self.scaling = scaling
    }

    public func resolved(
        compatibleWith traitCollection: UITraitCollection,
        fontFamily: XDFontFamily = .pingFangSC
    ) -> UIFont {
        let baseFont = fontName.flatMap { UIFont(name: $0, size: pointSize) }
            ?? fontFamily.font(ofSize: pointSize, weight: weight)
        guard scaling == .dynamic else { return baseFont }

        let metrics = UIFontMetrics(forTextStyle: textStyle)
        if let maximumPointSize {
            return metrics.scaledFont(
                for: baseFont,
                maximumPointSize: maximumPointSize,
                compatibleWith: traitCollection
            )
        }
        return metrics.scaledFont(for: baseFont, compatibleWith: traitCollection)
    }
}
