import UIKit

/// Snack-bar colors, typography, layout, and motion metrics.
public struct XDSnackBarTheme: Sendable {
    public let backgroundToken: XDColorToken
    public let highlightedBackgroundToken: XDColorToken
    public let messageToken: XDColorToken
    public let annotationToken: XDColorToken
    public let iconToken: XDColorToken
    public let componentColors: [XDColorToken: XDThemeColor]
    public let messageStyle: XDFontStyle
    public let annotationStyle: XDFontStyle
    public let radiusToken: XDRadiusToken
    public let disabledOpacityToken: XDOpacityToken
    public let motionToken: XDMotionToken
    public let minimumHeight: CGFloat
    public let maximumWidth: CGFloat
    public let screenHorizontalInset: CGFloat
    public let defaultBottomInset: CGFloat
    public let contentHorizontalInset: CGFloat
    public let contentVerticalInset: CGFloat
    public let iconSize: CGFloat
    public let iconSpacing: CGFloat
    public let annotationSpacing: CGFloat
    public let presentationOffset: CGFloat

    public init(
        backgroundToken: XDColorToken,
        highlightedBackgroundToken: XDColorToken,
        messageToken: XDColorToken,
        annotationToken: XDColorToken,
        iconToken: XDColorToken,
        componentColors: [XDColorToken: XDThemeColor] = [:],
        messageStyle: XDFontStyle,
        annotationStyle: XDFontStyle? = nil,
        radiusToken: XDRadiusToken = .md,
        disabledOpacityToken: XDOpacityToken = .disabled,
        motionToken: XDMotionToken = .standard,
        minimumHeight: CGFloat = 48,
        maximumWidth: CGFloat = 560,
        screenHorizontalInset: CGFloat = 20,
        defaultBottomInset: CGFloat = 16,
        contentHorizontalInset: CGFloat = 20,
        contentVerticalInset: CGFloat = 12,
        iconSize: CGFloat = 24,
        iconSpacing: CGFloat = 4,
        annotationSpacing: CGFloat = 12,
        presentationOffset: CGFloat = 12
    ) {
        self.backgroundToken = backgroundToken
        self.highlightedBackgroundToken = highlightedBackgroundToken
        self.messageToken = messageToken
        self.annotationToken = annotationToken
        self.iconToken = iconToken
        self.componentColors = componentColors
        self.messageStyle = messageStyle
        self.annotationStyle = annotationStyle ?? messageStyle
        self.radiusToken = radiusToken
        self.disabledOpacityToken = disabledOpacityToken
        self.motionToken = motionToken
        self.minimumHeight = minimumHeight
        self.maximumWidth = maximumWidth
        self.screenHorizontalInset = screenHorizontalInset
        self.defaultBottomInset = defaultBottomInset
        self.contentHorizontalInset = contentHorizontalInset
        self.contentVerticalInset = contentVerticalInset
        self.iconSize = iconSize
        self.iconSpacing = iconSpacing
        self.annotationSpacing = annotationSpacing
        self.presentationOffset = presentationOffset
    }

    public func merging(
        componentColors: [XDColorToken: XDThemeColor] = [:],
        maximumWidth: CGFloat? = nil,
        screenHorizontalInset: CGFloat? = nil,
        defaultBottomInset: CGFloat? = nil,
        contentHorizontalInset: CGFloat? = nil,
        contentVerticalInset: CGFloat? = nil,
        iconSize: CGFloat? = nil,
        iconSpacing: CGFloat? = nil,
        annotationSpacing: CGFloat? = nil,
        presentationOffset: CGFloat? = nil
    ) -> XDSnackBarTheme {
        XDSnackBarTheme(
            backgroundToken: backgroundToken,
            highlightedBackgroundToken: highlightedBackgroundToken,
            messageToken: messageToken,
            annotationToken: annotationToken,
            iconToken: iconToken,
            componentColors: self.componentColors.merging(componentColors, uniquingKeysWith: { _, new in new }),
            messageStyle: messageStyle,
            annotationStyle: annotationStyle,
            radiusToken: radiusToken,
            disabledOpacityToken: disabledOpacityToken,
            motionToken: motionToken,
            minimumHeight: minimumHeight,
            maximumWidth: maximumWidth ?? self.maximumWidth,
            screenHorizontalInset: screenHorizontalInset ?? self.screenHorizontalInset,
            defaultBottomInset: defaultBottomInset ?? self.defaultBottomInset,
            contentHorizontalInset: contentHorizontalInset ?? self.contentHorizontalInset,
            contentVerticalInset: contentVerticalInset ?? self.contentVerticalInset,
            iconSize: iconSize ?? self.iconSize,
            iconSpacing: iconSpacing ?? self.iconSpacing,
            annotationSpacing: annotationSpacing ?? self.annotationSpacing,
            presentationOffset: presentationOffset ?? self.presentationOffset
        )
    }

    func color(for token: XDColorToken, resolver: XDThemeResolver) -> UIColor {
        componentColors[token]?.resolved(compatibleWith: resolver.traitCollection) ?? resolver.color(token)
    }

    func font(for style: XDFontStyle, resolver: XDThemeResolver) -> UIFont {
        style.resolved(
            compatibleWith: resolver.traitCollection,
            fontFamily: resolver.theme.metrics.fontFamily
        )
    }

    func validationErrors() -> [String] {
        let nonnegative = [
            screenHorizontalInset, defaultBottomInset, contentHorizontalInset,
            contentVerticalInset, iconSpacing, annotationSpacing, presentationOffset
        ]
        let positive = [minimumHeight, maximumWidth, iconSize]
        guard nonnegative.allSatisfy({ $0.isFinite && $0 >= 0 }),
              positive.allSatisfy({ $0.isFinite && $0 > 0 }) else {
            return ["Snack-bar metrics must be finite and valid"]
        }
        return []
    }
}

public extension XDSnackBarTheme {
    static let `default`: XDSnackBarTheme = {
        let background = XDColorToken(rawValue: "snackBar.background")
        let highlightedBackground = XDColorToken(rawValue: "snackBar.background.highlighted")
        let message = XDColorToken(rawValue: "snackBar.message")
        let annotation = XDColorToken(rawValue: "snackBar.annotation")
        let icon = XDColorToken(rawValue: "snackBar.icon")
        let textStyle = XDFontStyle(
            pointSize: 13,
            weight: .regular,
            textStyle: .caption1,
            lineHeight: 19.5,
            maximumPointSize: 17
        )
        return XDSnackBarTheme(
            backgroundToken: background,
            highlightedBackgroundToken: highlightedBackground,
            messageToken: message,
            annotationToken: annotation,
            iconToken: icon,
            componentColors: [
                background: XDThemeColor(UIColor(hex: 0x484D54)),
                highlightedBackground: XDThemeColor(UIColor(hex: 0x3D4248)),
                message: XDThemeColor(.white),
                annotation: XDThemeColor(UIColor(hex: 0xABB2B6)),
                icon: XDThemeColor(.white)
            ],
            messageStyle: textStyle
        )
    }()
}
