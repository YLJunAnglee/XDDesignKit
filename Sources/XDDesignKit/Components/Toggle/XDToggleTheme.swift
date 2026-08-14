import UIKit

/// Toggle-specific colors and visual metrics resolved from an `XDThemeContext`.
public struct XDToggleTheme: Sendable {
    public let onTrackColor: XDThemeColor
    public let offTrackColor: XDThemeColor
    public let onThumbColor: XDThemeColor
    public let offThumbColor: XDThemeColor
    public let visualSize: CGSize
    public let trackSize: CGSize
    public let thumbDiameter: CGFloat
    public let thumbInset: CGFloat

    public init(
        onTrackColor: XDThemeColor,
        offTrackColor: XDThemeColor,
        onThumbColor: XDThemeColor,
        offThumbColor: XDThemeColor,
        visualSize: CGSize = CGSize(width: 52, height: 28),
        trackSize: CGSize = CGSize(width: 48, height: 26),
        thumbDiameter: CGFloat = 22,
        thumbInset: CGFloat = 2
    ) {
        self.onTrackColor = onTrackColor
        self.offTrackColor = offTrackColor
        self.onThumbColor = onThumbColor
        self.offThumbColor = offThumbColor
        self.visualSize = visualSize
        self.trackSize = trackSize
        self.thumbDiameter = thumbDiameter
        self.thumbInset = thumbInset
    }

    public func merging(
        onTrackColor: XDThemeColor? = nil,
        offTrackColor: XDThemeColor? = nil,
        onThumbColor: XDThemeColor? = nil,
        offThumbColor: XDThemeColor? = nil,
        visualSize: CGSize? = nil,
        trackSize: CGSize? = nil,
        thumbDiameter: CGFloat? = nil,
        thumbInset: CGFloat? = nil
    ) -> XDToggleTheme {
        XDToggleTheme(
            onTrackColor: onTrackColor ?? self.onTrackColor,
            offTrackColor: offTrackColor ?? self.offTrackColor,
            onThumbColor: onThumbColor ?? self.onThumbColor,
            offThumbColor: offThumbColor ?? self.offThumbColor,
            visualSize: visualSize ?? self.visualSize,
            trackSize: trackSize ?? self.trackSize,
            thumbDiameter: thumbDiameter ?? self.thumbDiameter,
            thumbInset: thumbInset ?? self.thumbInset
        )
    }

    func validationErrors() -> [String] {
        let values = [
            visualSize.width, visualSize.height,
            trackSize.width, trackSize.height,
            thumbDiameter, thumbInset
        ]
        let isValid = values.allSatisfy { $0.isFinite && $0 >= 0 }
            && visualSize.width > 0
            && visualSize.height > 0
            && trackSize.width > 0
            && trackSize.height > 0
            && trackSize.width <= visualSize.width
            && trackSize.height <= visualSize.height
            && thumbDiameter > 0
            && thumbDiameter + thumbInset * 2 <= trackSize.width
            && thumbDiameter + thumbInset * 2 <= trackSize.height
        return isValid ? [] : ["Toggle metrics must be finite and valid"]
    }
}

public extension XDToggleTheme {
    static let `default` = XDToggleTheme(
        onTrackColor: XDThemeColor(
            light: UIColor(hex: 0x4F5CE7),
            dark: UIColor(hex: 0x6F78FF)
        ),
        offTrackColor: XDThemeColor(
            light: UIColor(hex: 0xD9D9D9),
            dark: UIColor(hex: 0x2A2A2C)
        ),
        onThumbColor: XDThemeColor(
            light: .white,
            dark: UIColor(hex: 0xD5D5D7)
        ),
        offThumbColor: XDThemeColor(
            light: .white,
            dark: UIColor(hex: 0x898C91)
        )
    )
}
