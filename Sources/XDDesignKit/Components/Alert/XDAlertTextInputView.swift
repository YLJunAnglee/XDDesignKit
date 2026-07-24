import UIKit

/// Keeps the standard alert content renderer independent from the UIKit control
/// used for a particular text-input layout.
@MainActor
final class XDAlertTextInputView: UIView, XDThemeable {
    let xdThemeContext: XDThemeContext
    var onHeightChange: (() -> Void)?

    private let configuration: XDAlertTextFieldConfiguration
    private let textField: UITextField?
    private let textView: UITextView?
    private let placeholderLabel: UILabel?
    private var textFieldLengthController: XDAlertTextFieldLengthController?
    private var heightConstraint: NSLayoutConstraint!
    private var textFieldLeadingConstraint: NSLayoutConstraint?
    private var textFieldTrailingConstraint: NSLayoutConstraint?
    private var placeholderLeadingConstraint: NSLayoutConstraint?
    private var placeholderTrailingConstraint: NSLayoutConstraint?
    private var placeholderTopConstraint: NSLayoutConstraint?
    private var multilineLineHeight: CGFloat = 0
    private var multilineVerticalInset: CGFloat = 0
    private var isAtMaximumLength = false
    private var isAtMaximumHeight = false

    var text: String? {
        switch configuration.layout {
        case .singleLine:
            return textField?.text
        case .multiline:
            return textView?.text
        }
    }

    var primaryInputRect: CGRect {
        let inputView: UIView = textField ?? textView ?? self
        return inputView.convert(inputView.bounds, to: self)
    }

    init(configuration: XDAlertTextFieldConfiguration, themeContext: XDThemeContext) {
        self.configuration = configuration
        self.xdThemeContext = themeContext
        switch configuration.layout {
        case .singleLine:
            textField = UITextField()
            textView = nil
            placeholderLabel = nil
        case .multiline:
            textField = nil
            textView = UITextView()
            placeholderLabel = UILabel()
        }
        super.init(frame: .zero)
        setup()
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateMultilineHeight()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if xdNeedsThemeUpdate(after: previousTraitCollection) {
            xdApplyTheme()
        }
    }

    func focus() {
        (textField ?? textView)?.becomeFirstResponder()
    }

    func xdApplyTheme() {
        let resolver = xdThemeResolver
        let theme = resolver.theme.components.alert
        let font = theme.messageStyle.resolved(
            compatibleWith: traitCollection,
            fontFamily: resolver.theme.metrics.fontFamily
        )
        let textColor = theme.color(for: theme.inputTextToken, resolver: resolver)
        let placeholderColor = theme.color(for: theme.inputPlaceholderToken, resolver: resolver)

        backgroundColor = theme.color(for: theme.inputBackgroundToken, resolver: resolver)
        layer.cornerRadius = resolver.radius(.md)
        heightConstraint.constant = theme.inputHeight
        textFieldLeadingConstraint?.constant = theme.inputHorizontalInset
        textFieldTrailingConstraint?.constant = -theme.inputHorizontalInset

        if let textField {
            textField.font = font
            textField.textColor = textColor
            textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
            textField.attributedPlaceholder = NSAttributedString(
                string: configuration.placeholder ?? "",
                attributes: [.font: font, .foregroundColor: placeholderColor]
            )
        }

        if let textView, let placeholderLabel {
            let resolvedLineHeight = theme.messageStyle.lineHeight.map {
                $0 * font.pointSize / theme.messageStyle.pointSize
            } ?? font.lineHeight
            multilineLineHeight = resolvedLineHeight
            multilineVerticalInset = theme.inputVerticalInset

            let paragraph = NSMutableParagraphStyle()
            paragraph.minimumLineHeight = resolvedLineHeight
            paragraph.maximumLineHeight = resolvedLineHeight
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraph,
                .kern: theme.messageStyle.letterSpacing
            ]
            textView.textStorage.beginEditing()
            textView.textStorage.setAttributes(
                attributes,
                range: NSRange(location: 0, length: textView.textStorage.length)
            )
            textView.textStorage.endEditing()
            textView.typingAttributes = attributes
            textView.textContainerInset = UIEdgeInsets(
                top: theme.inputVerticalInset,
                left: theme.inputHorizontalInset,
                bottom: theme.inputVerticalInset,
                right: theme.inputHorizontalInset
            )
            textView.textContainer.lineFragmentPadding = 0
            placeholderLabel.font = font
            placeholderLabel.textColor = placeholderColor
            placeholderLeadingConstraint?.constant = theme.inputHorizontalInset
            placeholderTrailingConstraint?.constant = -theme.inputHorizontalInset
            placeholderTopConstraint?.constant = theme.inputVerticalInset
            updatePlaceholderVisibility()
        }

        updateMultilineHeight()
    }

    private func setup() {
        layer.masksToBounds = true
        heightConstraint = heightAnchor.constraint(equalToConstant: 1)
        heightConstraint.isActive = true

        switch configuration.layout {
        case .singleLine:
            setupTextField()
        case .multiline:
            setupTextView()
        }
    }

    private func setupTextField() {
        guard let textField else { return }
        textField.text = configuration.text
        textField.placeholder = configuration.placeholder
        textField.keyboardType = configuration.keyboardType
        textField.isSecureTextEntry = configuration.isSecureTextEntry
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.accessibilityLabel = configuration.placeholder
        let lengthController = XDAlertTextFieldLengthController(
            maximumLength: configuration.maximumLength
        )
        textFieldLengthController = lengthController
        textField.addTarget(
            lengthController,
            action: #selector(XDAlertTextFieldLengthController.textDidChange(_:)),
            for: .editingChanged
        )
        textField.addTarget(
            self,
            action: #selector(handleTextFieldChange(_:)),
            for: .editingChanged
        )
        lengthController.enforceMaximumLength(in: textField)

        addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        let theme = xdThemeResolver.theme.components.alert
        textFieldLeadingConstraint = textField.leadingAnchor.constraint(
            equalTo: leadingAnchor,
            constant: theme.inputHorizontalInset
        )
        textFieldTrailingConstraint = textField.trailingAnchor.constraint(
            equalTo: trailingAnchor,
            constant: -theme.inputHorizontalInset
        )
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: topAnchor),
            textFieldLeadingConstraint!,
            textFieldTrailingConstraint!,
            textField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupTextView() {
        guard let textView, let placeholderLabel else { return }
        textView.text = configuration.text
        textView.keyboardType = configuration.keyboardType
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.delegate = self
        textView.accessibilityLabel = configuration.placeholder
        textView.alwaysBounceVertical = false
        enforceMaximumLength(in: textView)

        placeholderLabel.text = configuration.placeholder
        placeholderLabel.isAccessibilityElement = false

        addSubview(textView)
        textView.addSubview(placeholderLabel)
        textView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLeadingConstraint = placeholderLabel.leadingAnchor.constraint(
            equalTo: textView.frameLayoutGuide.leadingAnchor
        )
        placeholderTrailingConstraint = placeholderLabel.trailingAnchor.constraint(
            lessThanOrEqualTo: textView.frameLayoutGuide.trailingAnchor
        )
        placeholderTopConstraint = placeholderLabel.topAnchor.constraint(
            equalTo: textView.frameLayoutGuide.topAnchor
        )
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),
            placeholderLeadingConstraint!,
            placeholderTrailingConstraint!,
            placeholderTopConstraint!
        ])
        updatePlaceholderVisibility()
    }

    private func updateMultilineHeight(notifyLimit: Bool = false) {
        guard let textView, textView.bounds.width > 0 else { return }
        let theme = xdThemeResolver.theme.components.alert
        let fittingHeight = textView.sizeThatFits(
            CGSize(width: textView.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        ).height
        let maximumHeight: CGFloat
        switch configuration.layout {
        case .singleLine:
            return
        case let .multiline(maximum):
            switch maximum {
            case let .lines(count):
                maximumHeight = 2 * multilineVerticalInset + multilineLineHeight * CGFloat(count)
            case let .height(height):
                maximumHeight = height
            case .unlimited:
                maximumHeight = .greatestFiniteMagnitude
            }
        }

        let targetHeight = min(
            max(fittingHeight, theme.inputHeight),
            max(maximumHeight, theme.inputHeight)
        )
        let shouldScroll = fittingHeight > targetHeight + 0.5
        let reachedHeightLimit: Bool
        switch configuration.layout {
        case .singleLine, .multiline(maximum: .unlimited):
            reachedHeightLimit = false
        case .multiline:
            let effectiveMaximum = max(maximumHeight, theme.inputHeight)
            reachedHeightLimit = fittingHeight >= effectiveMaximum - 0.5
        }
        if reachedHeightLimit && !isAtMaximumHeight && notifyLimit {
            configuration.onLimitReached?(.maximumHeight)
        }
        isAtMaximumHeight = reachedHeightLimit
        textView.isScrollEnabled = shouldScroll
        if !shouldScroll, textView.contentOffset != .zero {
            textView.setContentOffset(.zero, animated: false)
        }
        guard abs(heightConstraint.constant - targetHeight) > 0.5 else { return }
        heightConstraint.constant = targetHeight
        invalidateIntrinsicContentSize()
        onHeightChange?()
    }

    private func enforceMaximumLength(in textView: UITextView) {
        guard textView.markedTextRange == nil,
              let truncated = XDAlertTextLengthLimiter.truncatedText(
                textView.text,
                maximumLength: configuration.maximumLength
              ) else {
            return
        }
        textView.textStorage.setAttributedString(
            NSAttributedString(string: truncated, attributes: textView.typingAttributes)
        )
        textView.selectedRange = NSRange(location: truncated.utf16.count, length: 0)
    }

    @objc func handleTextFieldChange(_ textField: UITextField) {
        let reached = configuration.maximumLength.map { textField.text?.count ?? 0 >= $0 } ?? false
        if reached && !isAtMaximumLength {
            configuration.onLimitReached?(.maximumLength)
        }
        isAtMaximumLength = reached
    }

    private func updateLengthLimitState(for textView: UITextView) {
        let reached = configuration.maximumLength.map { textView.text.count >= $0 } ?? false
        if reached && !isAtMaximumLength {
            configuration.onLimitReached?(.maximumLength)
        }
        isAtMaximumLength = reached
    }

    private func updatePlaceholderVisibility() {
        placeholderLabel?.isHidden = !(textView?.text.isEmpty ?? true)
    }
}

extension XDAlertTextInputView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        enforceMaximumLength(in: textView)
        updateLengthLimitState(for: textView)
        updatePlaceholderVisibility()
        updateMultilineHeight(notifyLimit: true)
    }
}

enum XDAlertTextLengthLimiter {
    static func truncatedText(_ text: String, maximumLength: Int?) -> String? {
        guard let maximumLength, text.count > maximumLength else { return nil }
        let endIndex = text.index(text.startIndex, offsetBy: maximumLength)
        return String(text[..<endIndex])
    }
}
