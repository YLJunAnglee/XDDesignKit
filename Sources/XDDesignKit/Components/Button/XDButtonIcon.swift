import UIKit

/// Extensible semantic icon identifiers resolved by an `XDIconProviding` implementation.
public struct XDIconToken: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        precondition(!rawValue.isEmpty, "An icon token name must not be empty")
        self.rawValue = rawValue
    }

    public static let arrowForward = XDIconToken(rawValue: "chevron.right")
    public static let checkmarkCircle = XDIconToken(rawValue: "checkmark.circle")
    public static let refresh = XDIconToken(rawValue: "arrow.clockwise")
}

/// Semantic placement relative to the button title.
public struct XDButtonIconPlacement: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        precondition(!rawValue.isEmpty, "A button icon placement must not be empty")
        self.rawValue = rawValue
    }

    public static let leading = XDButtonIconPlacement(rawValue: "leading")
    public static let trailing = XDButtonIconPlacement(rawValue: "trailing")
    public static let top = XDButtonIconPlacement(rawValue: "top")
    public static let bottom = XDButtonIconPlacement(rawValue: "bottom")
    public static let only = XDButtonIconPlacement(rawValue: "only")
}

/// A resolved UIKit image and its directional behavior.
@MainActor
public struct XDResolvedIcon {
    public let image: UIImage
    public let mirrorsInRightToLeftLayout: Bool
    public let usesTemplateRendering: Bool

    public init(
        image: UIImage,
        mirrorsInRightToLeftLayout: Bool = false,
        usesTemplateRendering: Bool = true
    ) {
        self.image = image
        self.mirrorsInRightToLeftLayout = mirrorsInRightToLeftLayout
        self.usesTemplateRendering = usesTemplateRendering
    }
}

/// Resolves semantic icon tokens without coupling icons to theme snapshots.
@MainActor
public protocol XDIconProviding: AnyObject {
    func icon(
        for token: XDIconToken,
        compatibleWith traitCollection: UITraitCollection
    ) -> XDResolvedIcon?
}

/// Default provider backed by SF Symbols. Custom asset tokens can use an injected provider.
@MainActor
public final class XDSystemIconProvider: XDIconProviding {
    public static let shared = XDSystemIconProvider()

    public init() {}

    public func icon(
        for token: XDIconToken,
        compatibleWith traitCollection: UITraitCollection
    ) -> XDResolvedIcon? {
        guard let image = UIImage(systemName: token.rawValue) else { return nil }
        let directionalTokens: Set<XDIconToken> = [.arrowForward]
        return XDResolvedIcon(
            image: image,
            mirrorsInRightToLeftLayout: directionalTokens.contains(token),
            usesTemplateRendering: true
        )
    }
}
