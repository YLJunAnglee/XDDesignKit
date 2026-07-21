import UIKit

/// A coherent theme snapshot bound to the trait environment of one view.
/// Components should resolve every visual value through this type.
public struct XDThemeResolver {
    public let theme: XDTheme
    public let traitCollection: UITraitCollection

    public init(theme: XDTheme, traitCollection: UITraitCollection) {
        self.theme = theme
        self.traitCollection = traitCollection
    }

    public func color(_ token: XDColorToken) -> UIColor {
        theme.color(for: token, compatibleWith: traitCollection)
    }

    public func font(_ token: XDFontToken) -> UIFont {
        theme.metrics.fontStyle(for: token).resolved(
            compatibleWith: traitCollection,
            fontFamily: theme.metrics.fontFamily
        )
    }

    public func spacing(_ token: XDSpacingToken) -> CGFloat { theme.metrics.spacing(for: token) }
    public func radius(_ token: XDRadiusToken) -> CGFloat { theme.metrics.radius(for: token) }
    public func borderWidth(_ token: XDBorderToken) -> CGFloat {
        let value = theme.metrics.borderWidth(for: token)
        guard token == .hairline else { return value }
        return value / max(traitCollection.displayScale, 1)
    }
    public func opacity(_ token: XDOpacityToken) -> CGFloat { theme.metrics.opacity(for: token) }
    public func shadow(_ token: XDShadowToken) -> XDShadowStyle { theme.metrics.shadow(for: token) }
    public func motion(_ token: XDMotionToken) -> XDMotionStyle { theme.metrics.motion(for: token) }

    public func textAttributes(
        font fontToken: XDFontToken,
        color colorToken: XDColorToken
    ) -> [NSAttributedString.Key: Any] {
        let style = theme.metrics.fontStyle(for: fontToken)
        let resolvedFont = style.resolved(
            compatibleWith: traitCollection,
            fontFamily: theme.metrics.fontFamily
        )
        var attributes: [NSAttributedString.Key: Any] = [
            .font: resolvedFont,
            .foregroundColor: color(colorToken),
            .kern: style.letterSpacing
        ]
        if let lineHeight = style.lineHeight {
            let scaledLineHeight = lineHeight * resolvedFont.pointSize / style.pointSize
            let paragraph = NSMutableParagraphStyle()
            paragraph.minimumLineHeight = scaledLineHeight
            paragraph.maximumLineHeight = scaledLineHeight
            attributes[.paragraphStyle] = paragraph
        }
        return attributes
    }
}
