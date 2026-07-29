import UIKit

/// Bottom-sheet presentation metrics resolved from an `XDThemeContext`.
public struct XDBottomSheetTheme: Sendable {
    public let overlayColorToken: XDColorToken
    public let surfaceBackgroundToken: XDColorToken
    public let componentColors: [XDColorToken: XDThemeColor]
    public let overlayOpacityToken: XDOpacityToken
    public let surfaceRadiusToken: XDRadiusToken

    public init(
        overlayColorToken: XDColorToken = XDColorToken(rawValue: "bottomSheet.overlay"),
        surfaceBackgroundToken: XDColorToken = XDColorToken(rawValue: "bottomSheet.surface"),
        componentColors: [XDColorToken: XDThemeColor] = [:],
        overlayOpacityToken: XDOpacityToken = .overlay,
        surfaceRadiusToken: XDRadiusToken = .lg
    ) {
        self.overlayColorToken = overlayColorToken
        self.surfaceBackgroundToken = surfaceBackgroundToken
        self.componentColors = componentColors
        self.overlayOpacityToken = overlayOpacityToken
        self.surfaceRadiusToken = surfaceRadiusToken
    }

    public func merging(componentColors: [XDColorToken: XDThemeColor] = [:]) -> XDBottomSheetTheme {
        XDBottomSheetTheme(
            overlayColorToken: overlayColorToken,
            surfaceBackgroundToken: surfaceBackgroundToken,
            componentColors: self.componentColors.merging(componentColors, uniquingKeysWith: { _, new in new }),
            overlayOpacityToken: overlayOpacityToken,
            surfaceRadiusToken: surfaceRadiusToken
        )
    }

    func color(for token: XDColorToken, resolver: XDThemeResolver) -> UIColor {
        componentColors[token]?.resolved(compatibleWith: resolver.traitCollection) ?? resolver.color(token)
    }
}

public extension XDBottomSheetTheme {
    static let `default`: XDBottomSheetTheme = {
        let overlay = XDColorToken(rawValue: "bottomSheet.overlay")
        let surface = XDColorToken(rawValue: "bottomSheet.surface")
        return XDBottomSheetTheme(
            overlayColorToken: overlay,
            surfaceBackgroundToken: surface,
            componentColors: [
                overlay: XDThemeColor(light: .black, dark: .black),
                surface: XDThemeColor(light: UIColor(hex: 0xF4F5F7), dark: UIColor(hex: 0x24272D))
            ]
        )
    }()
}
