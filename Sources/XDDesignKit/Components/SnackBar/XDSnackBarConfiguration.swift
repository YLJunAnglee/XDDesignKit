import UIKit

/// Extensible semantic icons rendered by a snack bar.
public struct XDSnackBarIcon: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        precondition(!rawValue.isEmpty, "A snack-bar icon name must not be empty")
        self.rawValue = rawValue
    }

    public static let checkMark = XDSnackBarIcon(rawValue: "check.mark")
}

/// Immutable content, placement, and interaction policy for one snack bar.
@MainActor
public struct XDSnackBarConfiguration {
    public let message: String
    public let annotation: String?
    public let icon: XDSnackBarIcon?
    /// Visible time after the presentation animation. Pass nil to keep the snack bar visible until dismissal.
    public let duration: TimeInterval?
    /// Overrides the theme's distance from the host safe-area bottom edge.
    public let bottomInset: CGFloat?
    public let automaticallyDismissesOnTap: Bool
    public let onTap: (XDSnackBarActionContext) -> Void

    public init(
        message: String,
        annotation: String? = nil,
        icon: XDSnackBarIcon? = .checkMark,
        duration: TimeInterval? = 3,
        bottomInset: CGFloat? = nil,
        automaticallyDismissesOnTap: Bool = true,
        onTap: @escaping (XDSnackBarActionContext) -> Void
    ) {
        precondition(
            !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            "A snack-bar message must not be empty"
        )
        precondition(
            annotation.map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? true,
            "A snack-bar annotation must not be empty"
        )
        precondition(
            duration.map { $0.isFinite && $0 > 0 } ?? true,
            "A snack-bar duration must be finite and positive"
        )
        precondition(
            bottomInset.map { $0.isFinite && $0 >= 0 } ?? true,
            "A snack-bar bottom inset must be finite and nonnegative"
        )
        self.message = message
        self.annotation = annotation
        self.icon = icon
        self.duration = duration
        self.bottomInset = bottomInset
        self.automaticallyDismissesOnTap = automaticallyDismissesOnTap
        self.onTap = onTap
    }
}

/// The source that completed a snack-bar dismissal.
struct XDSnackBarDismissalReason: RawRepresentable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        precondition(!rawValue.isEmpty, "A snack-bar dismissal reason must not be empty")
        self.rawValue = rawValue
    }

    static let tap = Self(rawValue: "tap")
    static let timeout = Self(rawValue: "timeout")
    static let programmatic = Self(rawValue: "programmatic")
}

/// A presentation failure that leaves no visible or queued snack bar behind.
public struct XDSnackBarPresentationFailure: RawRepresentable, Error, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        precondition(!rawValue.isEmpty, "A snack-bar presentation failure must not be empty")
        self.rawValue = rawValue
    }

    public static let presenterNotAttachedToScene = Self(rawValue: "presenterNotAttachedToScene")
    public static let presenterUnavailable = Self(rawValue: "presenterUnavailable")
}
