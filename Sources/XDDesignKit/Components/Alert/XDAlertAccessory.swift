import UIKit

/// Controls how a standard alert text input lays out its editable content.
public enum XDAlertTextInputLayout: Hashable, Sendable {
    /// Preserves the compact, single-line text-field behavior.
    case singleLine
    /// Grows with wrapped or explicit new lines until the selected limit is reached.
    case multiline(maximum: XDAlertTextInputHeightLimit = .lines(4))
}

/// A mutually exclusive upper bound for a growing multiline alert input.
public enum XDAlertTextInputHeightLimit: Hashable, Sendable {
    /// Limits the visible editing area to a semantic number of text lines.
    case lines(Int)
    /// Limits the visible editing area to an absolute point height.
    case height(CGFloat)
    /// Lets the input grow with its content. The alert shell may still scroll to fit the screen.
    case unlimited
}

/// Identifies the input constraint reached while editing.
public enum XDAlertTextInputLimit: Hashable, Sendable {
    case maximumLength
    case maximumHeight
}

@MainActor
public struct XDAlertCheckboxConfiguration {
    public let title: String
    public let isSelected: Bool
    public let isEnabled: Bool

    public init(title: String, isSelected: Bool = false, isEnabled: Bool = true) {
        precondition(!title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "A checkbox title must not be empty")
        self.title = title
        self.isSelected = isSelected
        self.isEnabled = isEnabled
    }
}

@MainActor
public struct XDAlertTextFieldConfiguration {
    public let placeholder: String?
    public let text: String?
    public let keyboardType: UIKeyboardType
    public let isSecureTextEntry: Bool
    public let maximumLength: Int?
    /// Shows a right-aligned `current/maximum` count for a single-line input.
    /// Requires `maximumLength`; defaults to `false`.
    public let showsCharacterCount: Bool
    public let layout: XDAlertTextInputLayout
    public let onLimitReached: ((XDAlertTextInputLimit) -> Void)?

    public init(
        placeholder: String? = nil,
        text: String? = nil,
        keyboardType: UIKeyboardType = .default,
        isSecureTextEntry: Bool = false,
        maximumLength: Int? = nil,
        showsCharacterCount: Bool = false,
        layout: XDAlertTextInputLayout = .singleLine,
        onLimitReached: ((XDAlertTextInputLimit) -> Void)? = nil
    ) {
        if let maximumLength {
            precondition(maximumLength > 0, "A text field maximum length must be positive")
        }
        if showsCharacterCount {
            precondition(maximumLength != nil, "A character count requires a maximum length")
            precondition(layout == .singleLine, "A character count only supports the single-line layout")
        }
        switch layout {
        case .singleLine:
            break
        case let .multiline(maximum):
            precondition(
                !isSecureTextEntry,
                "Secure alert text input only supports the single-line layout"
            )
            switch maximum {
            case let .lines(count):
                precondition(count > 0, "A multiline text input line limit must be positive")
            case let .height(height):
                precondition(
                    height.isFinite && height > 0,
                    "A multiline text input height limit must be finite and positive"
                )
            case .unlimited:
                break
            }
        }
        self.placeholder = placeholder
        self.text = text
        self.keyboardType = keyboardType
        self.isSecureTextEntry = isSecureTextEntry
        self.maximumLength = maximumLength
        self.showsCharacterCount = showsCharacterCount
        self.layout = layout
        self.onLimitReached = onLimitReached
    }
}

/// Semantic name for configurations that may contain either a single-line or
/// multiline text input. `XDAlertTextFieldConfiguration` remains source-compatible.
public typealias XDAlertTextInputConfiguration = XDAlertTextFieldConfiguration

/// A deliberately bounded standard-content extension point.
@MainActor
public struct XDAlertAccessory {
    enum Storage {
        case checkbox(XDAlertCheckboxConfiguration)
        case textField(XDAlertTextFieldConfiguration)
    }

    let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
    }

    public static func checkbox(
        title: String,
        isSelected: Bool = false,
        isEnabled: Bool = true
    ) -> XDAlertAccessory {
        XDAlertAccessory(storage: .checkbox(.init(title: title, isSelected: isSelected, isEnabled: isEnabled)))
    }

    public static func textField(
        placeholder: String? = nil,
        text: String? = nil,
        keyboardType: UIKeyboardType = .default,
        isSecureTextEntry: Bool = false,
        maximumLength: Int? = nil,
        showsCharacterCount: Bool = false,
        layout: XDAlertTextInputLayout = .singleLine,
        onLimitReached: ((XDAlertTextInputLimit) -> Void)? = nil
    ) -> XDAlertAccessory {
        XDAlertAccessory(
            storage: .textField(
                .init(
                    placeholder: placeholder,
                    text: text,
                    keyboardType: keyboardType,
                    isSecureTextEntry: isSecureTextEntry,
                    maximumLength: maximumLength,
                    showsCharacterCount: showsCharacterCount,
                    layout: layout,
                    onLimitReached: onLimitReached
                )
            )
        )
    }

    /// Preferred semantic spelling for new call sites. `textField` remains
    /// available for source compatibility with existing alerts.
    public static func textInput(
        placeholder: String? = nil,
        text: String? = nil,
        keyboardType: UIKeyboardType = .default,
        isSecureTextEntry: Bool = false,
        maximumLength: Int? = nil,
        showsCharacterCount: Bool = false,
        layout: XDAlertTextInputLayout = .singleLine,
        onLimitReached: ((XDAlertTextInputLimit) -> Void)? = nil
    ) -> XDAlertAccessory {
        textField(
            placeholder: placeholder,
            text: text,
            keyboardType: keyboardType,
            isSecureTextEntry: isSecureTextEntry,
            maximumLength: maximumLength,
            showsCharacterCount: showsCharacterCount,
            layout: layout,
            onLimitReached: onLimitReached
        )
    }
}
