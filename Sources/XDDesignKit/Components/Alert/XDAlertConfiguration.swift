import Foundation

/// Controls the horizontal alignment of alert title and message text.
public enum XDAlertTextAlignment: Hashable, Sendable {
    /// Centers short text and uses natural leading alignment once it fills the available line width.
    case adaptive
    /// Always uses the natural leading edge, including in right-to-left layouts.
    case leading
    /// Always centers the text, including multiline content.
    case center
}

/// Immutable standard-alert content and dismissal policy.
@MainActor
public struct XDAlertConfiguration {
    public let title: String?
    public let message: String?
    public let illustration: XDAlertIllustration?
    public let accessory: XDAlertAccessory?
    public let actions: [XDAlertAction]
    public let allowsBackgroundDismissal: Bool
    public let showsCloseButton: Bool
    public let titleAlignment: XDAlertTextAlignment
    public let messageAlignment: XDAlertTextAlignment

    public init(
        title: String? = nil,
        message: String? = nil,
        illustration: XDAlertIllustration? = nil,
        accessory: XDAlertAccessory? = nil,
        actions: [XDAlertAction] = [],
        allowsBackgroundDismissal: Bool = false,
        showsCloseButton: Bool = false,
        titleAlignment: XDAlertTextAlignment = .adaptive,
        messageAlignment: XDAlertTextAlignment = .adaptive
    ) {
        precondition(
            title != nil || message != nil || illustration != nil || accessory != nil,
            "An alert must contain at least one content item"
        )
        precondition(
            !actions.isEmpty || allowsBackgroundDismissal || showsCloseButton,
            "An action-free alert must provide a dismissal path"
        )
        self.title = title
        self.message = message
        self.illustration = illustration
        self.accessory = accessory
        self.actions = actions
        self.allowsBackgroundDismissal = allowsBackgroundDismissal
        self.showsCloseButton = showsCloseButton
        self.titleAlignment = titleAlignment
        self.messageAlignment = messageAlignment
    }
}
