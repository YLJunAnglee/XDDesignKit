import UIKit

/// Alert-specific visual metrics. Values are resolved through the injected theme context.
public struct XDAlertTheme: Sendable {
    public let overlayColorToken: XDColorToken
    public let cardBackgroundToken: XDColorToken
    public let titleToken: XDColorToken
    public let messageToken: XDColorToken
    public let supportingTextToken: XDColorToken
    public let inputBackgroundToken: XDColorToken
    public let inputTextToken: XDColorToken
    public let inputPlaceholderToken: XDColorToken
    public let checkboxSelectedToken: XDColorToken
    public let checkboxUnselectedToken: XDColorToken
    public let componentColors: [XDColorToken: XDThemeColor]
    public let titleStyle: XDFontStyle
    public let messageStyle: XDFontStyle
    public let checkboxTextStyle: XDFontStyle
    public let supportingTextStyle: XDFontStyle
    public let cardRadiusToken: XDRadiusToken
    public let overlayOpacityToken: XDOpacityToken
    public let cardMaximumWidth: CGFloat
    public let screenHorizontalInset: CGFloat
    public let screenVerticalInset: CGFloat
    public let contentHorizontalInset: CGFloat
    public let contentVerticalInset: CGFloat
    public let sectionContentInset: CGFloat
    public let contentSpacing: CGFloat
    public let actionSpacing: CGFloat
    public let actionHorizontalSpacing: CGFloat
    public let inputHeight: CGFloat
    public let inputHorizontalInset: CGFloat
    public let inputVerticalInset: CGFloat
    public let illustrationMaximumSize: CGSize
    public let closeButtonSize: CGFloat
    public let checkboxIconSize: CGFloat
    public let checkboxTitleSpacing: CGFloat
    public let checkboxMinimumHeight: CGFloat
    public let checkboxMinimumHitTargetSize: CGFloat
    public let presentationScale: CGFloat

    public init(
        overlayColorToken: XDColorToken = XDColorToken(rawValue: "alert.overlay"),
        cardBackgroundToken: XDColorToken,
        titleToken: XDColorToken,
        messageToken: XDColorToken,
        supportingTextToken: XDColorToken,
        inputBackgroundToken: XDColorToken,
        inputTextToken: XDColorToken,
        inputPlaceholderToken: XDColorToken,
        checkboxSelectedToken: XDColorToken,
        checkboxUnselectedToken: XDColorToken,
        componentColors: [XDColorToken: XDThemeColor] = [:],
        titleStyle: XDFontStyle,
        messageStyle: XDFontStyle,
        checkboxTextStyle: XDFontStyle? = nil,
        supportingTextStyle: XDFontStyle,
        cardRadiusToken: XDRadiusToken,
        overlayOpacityToken: XDOpacityToken,
        cardMaximumWidth: CGFloat,
        screenHorizontalInset: CGFloat,
        screenVerticalInset: CGFloat,
        contentHorizontalInset: CGFloat,
        contentVerticalInset: CGFloat,
        sectionContentInset: CGFloat = 0,
        contentSpacing: CGFloat,
        actionSpacing: CGFloat,
        actionHorizontalSpacing: CGFloat,
        inputHeight: CGFloat,
        inputHorizontalInset: CGFloat = 16,
        inputVerticalInset: CGFloat = 12,
        illustrationMaximumSize: CGSize,
        closeButtonSize: CGFloat = 44,
        checkboxIconSize: CGFloat = 24,
        checkboxTitleSpacing: CGFloat = 8,
        checkboxMinimumHeight: CGFloat = 44,
        checkboxMinimumHitTargetSize: CGFloat = 44,
        presentationScale: CGFloat = 0.96
    ) {
        self.overlayColorToken = overlayColorToken
        self.cardBackgroundToken = cardBackgroundToken
        self.titleToken = titleToken
        self.messageToken = messageToken
        self.supportingTextToken = supportingTextToken
        self.inputBackgroundToken = inputBackgroundToken
        self.inputTextToken = inputTextToken
        self.inputPlaceholderToken = inputPlaceholderToken
        self.checkboxSelectedToken = checkboxSelectedToken
        self.checkboxUnselectedToken = checkboxUnselectedToken
        self.componentColors = componentColors
        self.titleStyle = titleStyle
        self.messageStyle = messageStyle
        self.checkboxTextStyle = checkboxTextStyle ?? messageStyle
        self.supportingTextStyle = supportingTextStyle
        self.cardRadiusToken = cardRadiusToken
        self.overlayOpacityToken = overlayOpacityToken
        self.cardMaximumWidth = cardMaximumWidth
        self.screenHorizontalInset = screenHorizontalInset
        self.screenVerticalInset = screenVerticalInset
        self.contentHorizontalInset = contentHorizontalInset
        self.contentVerticalInset = contentVerticalInset
        self.sectionContentInset = sectionContentInset
        self.contentSpacing = contentSpacing
        self.actionSpacing = actionSpacing
        self.actionHorizontalSpacing = actionHorizontalSpacing
        self.inputHeight = inputHeight
        self.inputHorizontalInset = inputHorizontalInset
        self.inputVerticalInset = inputVerticalInset
        self.illustrationMaximumSize = illustrationMaximumSize
        self.closeButtonSize = closeButtonSize
        self.checkboxIconSize = checkboxIconSize
        self.checkboxTitleSpacing = checkboxTitleSpacing
        self.checkboxMinimumHeight = checkboxMinimumHeight
        self.checkboxMinimumHitTargetSize = checkboxMinimumHitTargetSize
        self.presentationScale = presentationScale
    }

    public func buttonStyle(for appearance: XDAlertActionAppearance) -> XDButtonStyle {
        switch appearance {
        case .outlined: return .outline
        case .text: return .text
        default: return .primary
        }
    }

    public func merging(
        componentColors: [XDColorToken: XDThemeColor] = [:],
        cardMaximumWidth: CGFloat? = nil,
        screenHorizontalInset: CGFloat? = nil,
        screenVerticalInset: CGFloat? = nil,
        contentHorizontalInset: CGFloat? = nil,
        contentVerticalInset: CGFloat? = nil,
        sectionContentInset: CGFloat? = nil,
        contentSpacing: CGFloat? = nil,
        actionSpacing: CGFloat? = nil,
        actionHorizontalSpacing: CGFloat? = nil,
        inputHeight: CGFloat? = nil,
        inputHorizontalInset: CGFloat? = nil,
        inputVerticalInset: CGFloat? = nil,
        illustrationMaximumSize: CGSize? = nil,
        closeButtonSize: CGFloat? = nil,
        checkboxIconSize: CGFloat? = nil,
        checkboxTitleSpacing: CGFloat? = nil,
        checkboxMinimumHeight: CGFloat? = nil,
        checkboxMinimumHitTargetSize: CGFloat? = nil,
        presentationScale: CGFloat? = nil
    ) -> XDAlertTheme {
        XDAlertTheme(
            overlayColorToken: overlayColorToken,
            cardBackgroundToken: cardBackgroundToken,
            titleToken: titleToken,
            messageToken: messageToken,
            supportingTextToken: supportingTextToken,
            inputBackgroundToken: inputBackgroundToken,
            inputTextToken: inputTextToken,
            inputPlaceholderToken: inputPlaceholderToken,
            checkboxSelectedToken: checkboxSelectedToken,
            checkboxUnselectedToken: checkboxUnselectedToken,
            componentColors: self.componentColors.merging(componentColors, uniquingKeysWith: { _, new in new }),
            titleStyle: titleStyle,
            messageStyle: messageStyle,
            checkboxTextStyle: checkboxTextStyle,
            supportingTextStyle: supportingTextStyle,
            cardRadiusToken: cardRadiusToken,
            overlayOpacityToken: overlayOpacityToken,
            cardMaximumWidth: cardMaximumWidth ?? self.cardMaximumWidth,
            screenHorizontalInset: screenHorizontalInset ?? self.screenHorizontalInset,
            screenVerticalInset: screenVerticalInset ?? self.screenVerticalInset,
            contentHorizontalInset: contentHorizontalInset ?? self.contentHorizontalInset,
            contentVerticalInset: contentVerticalInset ?? self.contentVerticalInset,
            sectionContentInset: sectionContentInset ?? self.sectionContentInset,
            contentSpacing: contentSpacing ?? self.contentSpacing,
            actionSpacing: actionSpacing ?? self.actionSpacing,
            actionHorizontalSpacing: actionHorizontalSpacing ?? self.actionHorizontalSpacing,
            inputHeight: inputHeight ?? self.inputHeight,
            inputHorizontalInset: inputHorizontalInset ?? self.inputHorizontalInset,
            inputVerticalInset: inputVerticalInset ?? self.inputVerticalInset,
            illustrationMaximumSize: illustrationMaximumSize ?? self.illustrationMaximumSize,
            closeButtonSize: closeButtonSize ?? self.closeButtonSize,
            checkboxIconSize: checkboxIconSize ?? self.checkboxIconSize,
            checkboxTitleSpacing: checkboxTitleSpacing ?? self.checkboxTitleSpacing,
            checkboxMinimumHeight: checkboxMinimumHeight ?? self.checkboxMinimumHeight,
            checkboxMinimumHitTargetSize: checkboxMinimumHitTargetSize ?? self.checkboxMinimumHitTargetSize,
            presentationScale: presentationScale ?? self.presentationScale
        )
    }

    func color(for token: XDColorToken, resolver: XDThemeResolver) -> UIColor {
        componentColors[token]?.resolved(compatibleWith: resolver.traitCollection) ?? resolver.color(token)
    }

    func validationErrors() -> [String] {
        let values = [
            cardMaximumWidth, screenHorizontalInset, screenVerticalInset,
            contentHorizontalInset, contentVerticalInset, sectionContentInset, contentSpacing,
            actionSpacing, actionHorizontalSpacing, inputHeight, inputHorizontalInset,
            inputVerticalInset,
            illustrationMaximumSize.width, illustrationMaximumSize.height,
            closeButtonSize, checkboxIconSize, checkboxTitleSpacing,
            checkboxMinimumHeight, checkboxMinimumHitTargetSize, presentationScale
        ]
        return values.allSatisfy { $0.isFinite && $0 >= 0 }
            && cardMaximumWidth > 0
            && inputHeight > 0
            && closeButtonSize >= 44
            && checkboxIconSize > 0
            && checkboxMinimumHeight > 0
            && checkboxMinimumHitTargetSize >= 44
            && presentationScale > 0
            && presentationScale <= 1
            ? []
            : ["Alert metrics must be finite and valid"]
    }
}

public extension XDAlertTheme {
    static let `default`: XDAlertTheme = {
        let overlay = XDColorToken(rawValue: "alert.overlay")
        let message = XDColorToken(rawValue: "alert.message")
        let supporting = XDColorToken(rawValue: "alert.supporting")
        let inputBackground = XDColorToken(rawValue: "alert.input.background")
        let inputPlaceholder = XDColorToken(rawValue: "alert.input.placeholder")
        let checkboxSelected = XDColorToken(rawValue: "alert.checkbox.selected")
        let checkboxUnselected = XDColorToken(rawValue: "alert.checkbox.unselected")
        return XDAlertTheme(
            overlayColorToken: overlay,
            cardBackgroundToken: .backgroundPrimary,
            titleToken: .textPrimary,
            messageToken: message,
            supportingTextToken: supporting,
            inputBackgroundToken: inputBackground,
            inputTextToken: .textPrimary,
            inputPlaceholderToken: inputPlaceholder,
            checkboxSelectedToken: checkboxSelected,
            checkboxUnselectedToken: checkboxUnselected,
            componentColors: [
                overlay: XDThemeColor(light: .black, dark: .black),
                message: XDThemeColor(light: UIColor(hex: 0x484D54), dark: UIColor(hex: 0xD1D5DB)),
                supporting: XDThemeColor(light: UIColor(hex: 0xABB2B6), dark: UIColor(hex: 0x9DA5B4)),
                inputBackground: XDThemeColor(light: UIColor(hex: 0xECEDEF), dark: UIColor(hex: 0x2B2F36)),
                inputPlaceholder: XDThemeColor(light: UIColor(hex: 0xABB2B6), dark: UIColor(hex: 0x86909C)),
                checkboxSelected: XDThemeColor(light: .black, dark: .white),
                checkboxUnselected: XDThemeColor(light: UIColor(hex: 0xABB2B6), dark: UIColor(hex: 0xA9B0BB))
            ],
            titleStyle: XDFontStyle(pointSize: 16, weight: .semibold, textStyle: .headline, lineHeight: 22),
            messageStyle: XDFontStyle(pointSize: 16, weight: .regular, textStyle: .body, lineHeight: 24),
            checkboxTextStyle: XDFontStyle(pointSize: 16, weight: .regular, textStyle: .body, lineHeight: 22),
            supportingTextStyle: XDFontStyle(pointSize: 14, weight: .regular, textStyle: .caption1, lineHeight: 20),
            cardRadiusToken: .lg,
            overlayOpacityToken: .overlay,
            cardMaximumWidth: 300,
            screenHorizontalInset: 32,
            screenVerticalInset: 24,
            contentHorizontalInset: 14,
            contentVerticalInset: 14,
            sectionContentInset: 8,
            contentSpacing: 16,
            actionSpacing: 10,
            actionHorizontalSpacing: 10,
            inputHeight: 48,
            inputHorizontalInset: 16,
            inputVerticalInset: 12,
            illustrationMaximumSize: CGSize(width: 112, height: 112),
            closeButtonSize: 44,
            checkboxIconSize: 24,
            checkboxTitleSpacing: 8,
            checkboxMinimumHeight: 24,
            checkboxMinimumHitTargetSize: 44,
            presentationScale: 0.96
        )
    }()
}
