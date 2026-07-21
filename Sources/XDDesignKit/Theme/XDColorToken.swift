import Foundation

/// An extensible semantic color identifier.
///
/// This is a value type instead of an enum so adding a library token does not
/// break exhaustive switches in client applications. Applications may also
/// define private semantic tokens with `init(rawValue:)` and provide them in a
/// complete theme.
public struct XDColorToken: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        precondition(!rawValue.isEmpty, "A color token name must not be empty")
        self.rawValue = rawValue
    }
}

public extension XDColorToken {
    static let brandPrimary = XDColorToken(rawValue: "brand.primary")
    static let brandPrimaryHighlighted = XDColorToken(rawValue: "brand.primary.highlighted")
    static let brandPrimaryDisabled = XDColorToken(rawValue: "brand.primary.disabled")
    static let brandPrimarySubtle = XDColorToken(rawValue: "brand.primary.subtle")

    static let textPrimary = XDColorToken(rawValue: "text.primary")
    static let textSecondary = XDColorToken(rawValue: "text.secondary")
    static let textTertiary = XDColorToken(rawValue: "text.tertiary")
    static let textInverse = XDColorToken(rawValue: "text.inverse")

    static let backgroundPrimary = XDColorToken(rawValue: "background.primary")
    static let backgroundSecondary = XDColorToken(rawValue: "background.secondary")
    static let backgroundHighlighted = XDColorToken(rawValue: "background.highlighted")
    static let backgroundDisabled = XDColorToken(rawValue: "background.disabled")

    static let borderPrimary = XDColorToken(rawValue: "border.primary")
    static let borderStrong = XDColorToken(rawValue: "border.strong")
    static let shadowPrimary = XDColorToken(rawValue: "shadow.primary")

    /// Built-in foundation tokens. Component-specific colors belong in the
    /// corresponding component appearance and are intentionally absent here.
    static let allCases: [XDColorToken] = [
        .brandPrimary,
        .brandPrimaryHighlighted,
        .brandPrimaryDisabled,
        .brandPrimarySubtle,
        .textPrimary,
        .textSecondary,
        .textTertiary,
        .textInverse,
        .backgroundPrimary,
        .backgroundSecondary,
        .backgroundHighlighted,
        .backgroundDisabled,
        .borderPrimary,
        .borderStrong,
        .shadowPrimary
    ]
}
