import Foundation

/// Semantic meaning of an alert action. The theme decides its final colors.
public struct XDAlertActionRole: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        precondition(!rawValue.isEmpty, "An alert action role must not be empty")
        self.rawValue = rawValue
    }

    public static let normal = XDAlertActionRole(rawValue: "normal")
    public static let cancel = XDAlertActionRole(rawValue: "cancel")
    public static let destructive = XDAlertActionRole(rawValue: "destructive")
}

/// Visual treatment of an alert action. This is intentionally independent from its role.
public struct XDAlertActionAppearance: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        precondition(!rawValue.isEmpty, "An alert action appearance must not be empty")
        self.rawValue = rawValue
    }

    public static let filled = XDAlertActionAppearance(rawValue: "filled")
    public static let outlined = XDAlertActionAppearance(rawValue: "outlined")
    public static let outlinedTransparent = XDAlertActionAppearance(rawValue: "outlinedTransparent")
    public static let text = XDAlertActionAppearance(rawValue: "text")
}

/// A user operation rendered in an alert action area.
@MainActor
public struct XDAlertAction {
    public let title: String
    public let role: XDAlertActionRole
    public let appearance: XDAlertActionAppearance
    public let automaticallyDismisses: Bool
    public let handler: ((XDAlertActionContext) -> Void)?

    public init(
        title: String,
        role: XDAlertActionRole = .normal,
        appearance: XDAlertActionAppearance = .filled,
        automaticallyDismisses: Bool = true,
        handler: ((XDAlertActionContext) -> Void)? = nil
    ) {
        precondition(!title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "An alert action title must not be empty")
        self.title = title
        self.role = role
        self.appearance = appearance
        self.automaticallyDismisses = automaticallyDismisses
        self.handler = handler
    }

    public static func primary(
        _ title: String,
        automaticallyDismisses: Bool = true,
        handler: ((XDAlertActionContext) -> Void)? = nil
    ) -> XDAlertAction {
        XDAlertAction(
            title: title,
            appearance: .filled,
            automaticallyDismisses: automaticallyDismisses,
            handler: handler
        )
    }

    public static func cancel(
        _ title: String,
        automaticallyDismisses: Bool = true,
        handler: ((XDAlertActionContext) -> Void)? = nil
    ) -> XDAlertAction {
        XDAlertAction(
            title: title,
            role: .cancel,
            appearance: .outlinedTransparent,
            automaticallyDismisses: automaticallyDismisses,
            handler: handler
        )
    }

    public static func destructive(
        _ title: String,
        automaticallyDismisses: Bool = true,
        handler: ((XDAlertActionContext) -> Void)? = nil
    ) -> XDAlertAction {
        XDAlertAction(
            title: title,
            role: .destructive,
            appearance: .filled,
            automaticallyDismisses: automaticallyDismisses,
            handler: handler
        )
    }

    public static func text(
        _ title: String,
        automaticallyDismisses: Bool = true,
        handler: ((XDAlertActionContext) -> Void)? = nil
    ) -> XDAlertAction {
        XDAlertAction(
            title: title,
            appearance: .text,
            automaticallyDismisses: automaticallyDismisses,
            handler: handler
        )
    }
}
