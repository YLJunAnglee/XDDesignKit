import UIKit

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

    public init(
        placeholder: String? = nil,
        text: String? = nil,
        keyboardType: UIKeyboardType = .default,
        isSecureTextEntry: Bool = false,
        maximumLength: Int? = nil
    ) {
        if let maximumLength {
            precondition(maximumLength > 0, "A text field maximum length must be positive")
        }
        self.placeholder = placeholder
        self.text = text
        self.keyboardType = keyboardType
        self.isSecureTextEntry = isSecureTextEntry
        self.maximumLength = maximumLength
    }
}

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
        maximumLength: Int? = nil
    ) -> XDAlertAccessory {
        XDAlertAccessory(
            storage: .textField(
                .init(
                    placeholder: placeholder,
                    text: text,
                    keyboardType: keyboardType,
                    isSecureTextEntry: isSecureTextEntry,
                    maximumLength: maximumLength
                )
            )
        )
    }
}
