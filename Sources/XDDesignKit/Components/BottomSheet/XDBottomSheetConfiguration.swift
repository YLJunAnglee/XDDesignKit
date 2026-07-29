import UIKit

/// Controls how a bottom sheet resolves its height.
@MainActor
public struct XDBottomSheetHeight: Hashable {
    enum Storage: Hashable { case content(CGFloat?), fixed(CGFloat), fraction(CGFloat) }
    let storage: Storage

    /// Fits the supplied content, up to the available sheet height.
    public static let content = XDBottomSheetHeight(storage: .content(nil))

    /// Fits the supplied content, capped at the supplied height before the screen cap is applied.
    public static func content(maximum: CGFloat) -> XDBottomSheetHeight {
        precondition(maximum.isFinite && maximum > 0, "The maximum content height must be finite and positive")
        return XDBottomSheetHeight(storage: .content(maximum))
    }

    /// Uses a fixed height before the available screen height cap is applied.
    public static func fixed(_ height: CGFloat) -> XDBottomSheetHeight {
        precondition(height.isFinite && height > 0, "The fixed sheet height must be finite and positive")
        return XDBottomSheetHeight(storage: .fixed(height))
    }

    /// Uses a fraction of the available sheet height.
    public static func fraction(_ value: CGFloat) -> XDBottomSheetHeight {
        precondition(value.isFinite && value > 0 && value <= 1, "The sheet height fraction must be in 0...1")
        return XDBottomSheetHeight(storage: .fraction(value))
    }
}

/// Controls horizontal placement of a bottom sheet.
@MainActor
public struct XDBottomSheetWidth: Hashable {
    enum Storage: Hashable { case fullWidth, horizontalInsets(CGFloat), centered(CGFloat) }
    let storage: Storage

    /// Fills the entire window width, including horizontal safe-area background regions.
    public static let fullWidth = XDBottomSheetWidth(storage: .fullWidth)

    /// Insets both horizontal edges by the supplied amount.
    public static func horizontalInsets(_ value: CGFloat) -> XDBottomSheetWidth {
        precondition(value.isFinite && value >= 0, "The horizontal inset must be finite and non-negative")
        return XDBottomSheetWidth(storage: .horizontalInsets(value))
    }

    /// Centers a sheet whose width does not exceed the supplied value.
    public static func centered(maximumWidth: CGFloat) -> XDBottomSheetWidth {
        precondition(maximumWidth.isFinite && maximumWidth > 0, "The maximum sheet width must be finite and positive")
        return XDBottomSheetWidth(storage: .centered(maximumWidth))
    }
}

/// Immutable layout and interactive-dismissal policy for a bottom sheet.
@MainActor
public struct XDBottomSheetConfiguration {
    public let height: XDBottomSheetHeight
    public let width: XDBottomSheetWidth
    public let allowsBackgroundDismissal: Bool
    public let allowsSwipeDismissal: Bool

    public init(
        height: XDBottomSheetHeight = .content,
        width: XDBottomSheetWidth = .fullWidth,
        allowsBackgroundDismissal: Bool = true,
        allowsSwipeDismissal: Bool = true
    ) {
        self.height = height
        self.width = width
        self.allowsBackgroundDismissal = allowsBackgroundDismissal
        self.allowsSwipeDismissal = allowsSwipeDismissal
    }
}

/// The source that initiated a completed sheet dismissal.
public struct XDBottomSheetDismissalReason: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        precondition(!rawValue.isEmpty, "A bottom sheet dismissal reason must not be empty")
        self.rawValue = rawValue
    }

    public static let backgroundTap = Self(rawValue: "backgroundTap")
    public static let swipe = Self(rawValue: "swipe")
    public static let programmatic = Self(rawValue: "programmatic")
    public static let accessibilityEscape = Self(rawValue: "accessibilityEscape")
    public static let system = Self(rawValue: "system")
}

/// A presentation failure that leaves no active sheet behind.
public struct XDBottomSheetPresentationFailure: RawRepresentable, Error, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        precondition(!rawValue.isEmpty, "A bottom sheet presentation failure must not be empty")
        self.rawValue = rawValue
    }

    public static let presenterNotAttachedToScene = Self(rawValue: "presenterNotAttachedToScene")
    public static let presenterUnavailable = Self(rawValue: "presenterUnavailable")
    public static let presentationRejected = Self(rawValue: "presentationRejected")
}

/// Lifecycle callbacks for one bottom-sheet presentation.
@MainActor
public struct XDBottomSheetEvents {
    public let onDidPresent: (() -> Void)?
    public let onWillDismiss: ((XDBottomSheetDismissalReason) -> Void)?
    public let onDidDismiss: ((XDBottomSheetDismissalReason) -> Void)?

    public init(
        onDidPresent: (() -> Void)? = nil,
        onWillDismiss: ((XDBottomSheetDismissalReason) -> Void)? = nil,
        onDidDismiss: ((XDBottomSheetDismissalReason) -> Void)? = nil
    ) {
        self.onDidPresent = onDidPresent
        self.onWillDismiss = onWillDismiss
        self.onDidDismiss = onDidDismiss
    }
}
