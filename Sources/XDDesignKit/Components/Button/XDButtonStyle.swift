import UIKit

/// Extensible button style identifiers. Adding a built-in style is source-compatible.
public struct XDButtonStyle: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { precondition(!rawValue.isEmpty); self.rawValue = rawValue }

    public static let primary = XDButtonStyle(rawValue: "primary")
    public static let brand = XDButtonStyle(rawValue: "brand")
    public static let secondary = XDButtonStyle(rawValue: "secondary")
    public static let outline = XDButtonStyle(rawValue: "outline")
    public static let text = XDButtonStyle(rawValue: "text")
    public static let gradient = XDButtonStyle(rawValue: "gradient")
    public static let allCases: [XDButtonStyle] = [.primary, .brand, .secondary, .outline, .text, .gradient]
}

/// Extensible button size identifiers. A theme supplies the metric for each size.
public struct XDButtonSize: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { precondition(!rawValue.isEmpty); self.rawValue = rawValue }

    public static let large = XDButtonSize(rawValue: "large")
    public static let medium = XDButtonSize(rawValue: "medium")
    public static let small = XDButtonSize(rawValue: "small")
    public static let allCases: [XDButtonSize] = [.large, .medium, .small]

    func height(in theme: XDTheme) -> CGFloat {
        metric(in: theme).height
    }

    func contentInsets(in theme: XDTheme) -> UIEdgeInsets {
        let metric = metric(in: theme)
        return UIEdgeInsets(
            top: metric.verticalPadding,
            left: metric.horizontalPadding,
            bottom: metric.verticalPadding,
            right: metric.horizontalPadding
        )
    }

    func metric(in theme: XDTheme) -> XDButtonMetric {
        theme.components.button.metric(for: XDButtonMetricToken(rawValue: rawValue))
    }
}
