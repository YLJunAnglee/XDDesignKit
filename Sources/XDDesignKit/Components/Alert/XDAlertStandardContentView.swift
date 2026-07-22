import UIKit

@MainActor
final class XDAlertStandardContentView: UIView, XDThemeable {
    let xdThemeContext: XDThemeContext

    private let configuration: XDAlertConfiguration
    private let onAction: (Int) -> Void
    private let rootStack = UIStackView()
    private let titleLabel = XDAlertAdaptiveAlignmentLabel()
    private let messageLabel = XDAlertAdaptiveAlignmentLabel()
    private var titleContainer: XDAlertInsetContainer?
    private var messageContainer: XDAlertInsetContainer?
    private var textFieldContainer: XDAlertInsetContainer?
    private var actionContainer: XDAlertInsetContainer?
    private var captionLabels: [XDAlertAdaptiveAlignmentLabel] = []
    private var actionButtons: [XDButton] = []
    private var actionStack: UIStackView?
    private var actionStackUsesHorizontalLayout = false
    private var checkboxView: XDAlertCheckboxView?
    private var textField: UITextField?
    private var textFieldLengthController: XDAlertTextFieldLengthController?
    private var inputHeightConstraint: NSLayoutConstraint?
    private var closeButton: UIButton?
    private var closeWidthConstraint: NSLayoutConstraint?
    private var closeHeightConstraint: NSLayoutConstraint?
    private var closeHeaderHeightConstraint: NSLayoutConstraint?
    private var illustrationWidthConstraint: NSLayoutConstraint?
    private var illustrationHeightConstraint: NSLayoutConstraint?
    private let onClose: () -> Void

    var checkboxIsSelected: Bool? { checkboxView?.isSelected }
    var textFieldText: String? { textField?.text }
    var primaryInputRect: CGRect? {
        guard let textField else { return nil }
        return textField.convert(textField.bounds, to: self)
    }

    init(
        configuration: XDAlertConfiguration,
        themeContext: XDThemeContext,
        onAction: @escaping (Int) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.configuration = configuration
        self.xdThemeContext = themeContext
        self.onAction = onAction
        self.onClose = onClose
        super.init(frame: .zero)
        setup()
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    required init?(coder: NSCoder) { nil }

    func focusPrimaryInput() {
        textField?.becomeFirstResponder()
    }

    private func setup() {
        rootStack.axis = .vertical
        rootStack.alignment = .fill
        addSubview(rootStack)
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: topAnchor),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        if configuration.showsCloseButton { makeCloseHeader() }
        makeTitle()
        makeIllustration()
        makeMessage()
        makeAccessory()
        if !configuration.actions.isEmpty {
            rootStack.addArrangedSubview(makeActionArea())
        }
    }

    private func makeCloseHeader() {
        let header = UIView()
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        close.accessibilityLabel = "关闭"
        close.accessibilityTraits = .button
        closeButton = close
        header.addSubview(close)
        close.translatesAutoresizingMaskIntoConstraints = false
        closeWidthConstraint = close.widthAnchor.constraint(equalToConstant: 1)
        closeHeightConstraint = close.heightAnchor.constraint(equalToConstant: 1)
        closeHeaderHeightConstraint = header.heightAnchor.constraint(equalToConstant: 1)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: header.topAnchor),
            close.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            closeWidthConstraint!,
            closeHeightConstraint!,
            closeHeaderHeightConstraint!
        ])
        rootStack.addArrangedSubview(header)
    }

    private func makeTitle() {
        guard let title = configuration.title else { return }
        titleLabel.text = title
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.alignmentMode = configuration.titleAlignment
        titleLabel.onTextAlignmentChange = { [weak self, weak titleLabel] alignment in
            guard let self, let titleLabel else { return }
            let theme = self.xdThemeResolver.theme.components.alert
            self.apply(
                text: titleLabel,
                style: theme.titleStyle,
                color: theme.color(for: theme.titleToken, resolver: self.xdThemeResolver),
                alignment: alignment
            )
        }
        let container = XDAlertInsetContainer(contentView: titleLabel)
        titleContainer = container
        rootStack.addArrangedSubview(container)
    }

    private func makeIllustration() {
        guard let illustration = configuration.illustration else { return }
        let imageView = UIImageView(image: illustration.image)
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = illustration.accessibilityLabel != nil
        imageView.accessibilityLabel = illustration.accessibilityLabel
        let imageContainer = UIView()
        imageContainer.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        illustrationWidthConstraint = imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 1)
        illustrationHeightConstraint = imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 1)
        NSLayoutConstraint.activate([
            illustrationWidthConstraint!,
            illustrationHeightConstraint!,
            imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            imageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor)
        ])
        rootStack.addArrangedSubview(imageContainer)

        if let caption = illustration.caption {
            let captionLabel = XDAlertAdaptiveAlignmentLabel()
            captionLabel.text = caption
            captionLabel.numberOfLines = 0
            captionLabel.adjustsFontForContentSizeCategory = true
            captionLabel.onTextAlignmentChange = { [weak self, weak captionLabel] _ in
                guard let self, let captionLabel else { return }
                self.apply(
                    text: captionLabel,
                    style: self.xdThemeResolver.theme.components.alert.supportingTextStyle,
                    color: self.xdThemeResolver.theme.components.alert.color(
                        for: self.xdThemeResolver.theme.components.alert.supportingTextToken,
                        resolver: self.xdThemeResolver
                    )
                )
            }
            captionLabels.append(captionLabel)
            rootStack.addArrangedSubview(captionLabel)
        }
    }

    private func makeMessage() {
        guard let message = configuration.message else { return }
        messageLabel.text = message
        messageLabel.numberOfLines = 0
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.alignmentMode = configuration.messageAlignment
        messageLabel.onTextAlignmentChange = { [weak self, weak messageLabel] alignment in
            guard let self, let messageLabel else { return }
            let theme = self.xdThemeResolver.theme.components.alert
            self.apply(
                text: messageLabel,
                style: theme.messageStyle,
                color: theme.color(for: theme.messageToken, resolver: self.xdThemeResolver),
                alignment: alignment
            )
        }
        let container = XDAlertInsetContainer(contentView: messageLabel)
        messageContainer = container
        rootStack.addArrangedSubview(container)
    }

    private func makeAccessory() {
        guard let accessory = configuration.accessory else { return }
        switch accessory.storage {
        case let .checkbox(configuration):
            let checkbox = XDAlertCheckboxView(configuration: configuration, themeContext: xdThemeContext)
            checkboxView = checkbox
            rootStack.addArrangedSubview(checkbox)
        case let .textField(configuration):
            let field = UITextField()
            field.text = configuration.text
            field.placeholder = configuration.placeholder
            field.keyboardType = configuration.keyboardType
            field.isSecureTextEntry = configuration.isSecureTextEntry
            field.borderStyle = .none
            field.layer.masksToBounds = true
            field.accessibilityLabel = configuration.placeholder
            let lengthController = XDAlertTextFieldLengthController(maximumLength: configuration.maximumLength)
            textFieldLengthController = lengthController
            field.addTarget(lengthController, action: #selector(XDAlertTextFieldLengthController.textDidChange(_:)), for: .editingChanged)
            lengthController.enforceMaximumLength(in: field)
            textField = field
            inputHeightConstraint = field.heightAnchor.constraint(equalToConstant: 1)
            inputHeightConstraint?.isActive = true
            let container = XDAlertInsetContainer(contentView: field)
            textFieldContainer = container
            rootStack.addArrangedSubview(container)
        }
    }

    func xdApplyTheme() {
        let resolver = xdThemeResolver
        let theme = resolver.theme.components.alert
        rootStack.spacing = theme.contentSpacing
        apply(
            text: titleLabel,
            style: theme.titleStyle,
            color: theme.color(for: theme.titleToken, resolver: resolver),
            alignment: initialAlignment(for: configuration.titleAlignment, adaptiveFallback: .center)
        )
        apply(
            text: messageLabel,
            style: theme.messageStyle,
            color: theme.color(for: theme.messageToken, resolver: resolver),
            alignment: initialAlignment(for: configuration.messageAlignment, adaptiveFallback: .natural)
        )
        captionLabels.forEach {
            apply(text: $0, style: theme.supportingTextStyle, color: theme.color(for: theme.supportingTextToken, resolver: resolver))
        }

        let sectionInset = theme.sectionContentInset
        let titleAndMessageAreAdjacent = configuration.title != nil
            && configuration.message != nil
            && configuration.illustration == nil
        titleContainer?.contentInsets = UIEdgeInsets(
            top: sectionInset,
            left: sectionInset,
            bottom: titleAndMessageAreAdjacent ? 0 : sectionInset,
            right: sectionInset
        )
        messageContainer?.contentInsets = UIEdgeInsets(
            top: titleAndMessageAreAdjacent ? 0 : sectionInset,
            left: sectionInset,
            bottom: sectionInset,
            right: sectionInset
        )
        textFieldContainer?.contentInsets = UIEdgeInsets(
            top: 0,
            left: sectionInset,
            bottom: 0,
            right: sectionInset
        )
        actionContainer?.contentInsets = UIEdgeInsets(
            top: sectionInset,
            left: sectionInset,
            bottom: sectionInset,
            right: sectionInset
        )

        if let textField {
            let inputFont = theme.messageStyle.resolved(
                compatibleWith: traitCollection,
                fontFamily: resolver.theme.metrics.fontFamily
            )
            textField.font = inputFont
            textField.textColor = theme.color(for: theme.inputTextToken, resolver: resolver)
            textField.backgroundColor = theme.color(for: theme.inputBackgroundToken, resolver: resolver)
            textField.layer.cornerRadius = resolver.radius(.md)
            textField.leftView = spacer(width: theme.contentSpacing)
            textField.leftViewMode = .always
            textField.rightView = spacer(width: theme.contentSpacing)
            textField.rightViewMode = .always
            let placeholder = textField.placeholder ?? ""
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [
                    .font: inputFont,
                    .foregroundColor: theme.color(for: theme.inputPlaceholderToken, resolver: resolver)
                ]
            )
            inputHeightConstraint?.constant = theme.inputHeight
        }

        closeButton?.tintColor = theme.color(for: theme.titleToken, resolver: resolver)
        closeWidthConstraint?.constant = theme.closeButtonSize
        closeHeightConstraint?.constant = theme.closeButtonSize
        closeHeaderHeightConstraint?.constant = theme.closeButtonSize
        illustrationWidthConstraint?.constant = theme.illustrationMaximumSize.width
        illustrationHeightConstraint?.constant = theme.illustrationMaximumSize.height
        actionStack?.spacing = actionStackUsesHorizontalLayout ? theme.actionHorizontalSpacing : theme.actionSpacing
        checkboxView?.xdApplyTheme()
        actionButtons.forEach { $0.bindThemeContext(xdThemeContext) }
        setNeedsLayout()
    }

    func setActionLoading(_ isLoading: Bool, at index: Int) {
        guard actionButtons.indices.contains(index) else { return }
        actionButtons[index].isLoading = isLoading
    }

    private func makeActionArea() -> UIView {
        let regularActions = configuration.actions.filter { $0.appearance != .text }
        actionStackUsesHorizontalLayout = configuration.actions.count == 2 && regularActions.count == 2
        let stack = UIStackView()
        stack.axis = actionStackUsesHorizontalLayout ? .horizontal : .vertical
        stack.alignment = .fill
        stack.distribution = actionStackUsesHorizontalLayout ? .fillEqually : .fill
        actionStack = stack

        configuration.actions.enumerated().forEach { index, action in
            let size: XDButtonSize = action.appearance == .text ? .small : .large
            let button = XDButton(
                style: xdThemeContext.currentTheme.components.alert.buttonStyle(for: action.appearance),
                size: size,
                themeContext: xdThemeContext
            )
            button.setTitle(action.title, for: .normal)
            button.onTap = { [weak self] in self?.onAction(index) }
            actionButtons.append(button)
            stack.addArrangedSubview(button)
        }
        let container = XDAlertInsetContainer(contentView: stack)
        actionContainer = container
        return container
    }

    private func apply(
        text label: UILabel,
        style: XDFontStyle,
        color: UIColor,
        alignment: NSTextAlignment? = nil
    ) {
        guard let text = label.text else { return }
        let font = style.resolved(compatibleWith: traitCollection, fontFamily: xdThemeContext.currentTheme.metrics.fontFamily)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment ?? label.textAlignment
        if let lineHeight = style.lineHeight {
            let scaled = lineHeight * font.pointSize / style.pointSize
            paragraph.minimumLineHeight = scaled
            paragraph.maximumLineHeight = scaled
        }
        label.textAlignment = paragraph.alignment
        label.attributedText = NSAttributedString(
            string: text,
            attributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph, .kern: style.letterSpacing]
        )
    }

    private func initialAlignment(
        for alignment: XDAlertTextAlignment,
        adaptiveFallback: NSTextAlignment
    ) -> NSTextAlignment {
        switch alignment {
        case .adaptive: return adaptiveFallback
        case .leading: return .natural
        case .center: return .center
        }
    }

    private func spacer(width: CGFloat) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 1))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
        return view
    }

    @objc private func handleClose() { onClose() }
}

@MainActor
private final class XDAlertInsetContainer: UIView {
    private var topConstraint: NSLayoutConstraint!
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!

    var contentInsets: UIEdgeInsets = .zero {
        didSet { updateConstraintsForInsets() }
    }

    init(contentView: UIView) {
        super.init(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        topConstraint = contentView.topAnchor.constraint(equalTo: topAnchor)
        leadingConstraint = contentView.leadingAnchor.constraint(equalTo: leadingAnchor)
        trailingConstraint = contentView.trailingAnchor.constraint(equalTo: trailingAnchor)
        bottomConstraint = contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        addSubview(contentView)
        NSLayoutConstraint.activate([
            topConstraint,
            leadingConstraint,
            trailingConstraint,
            bottomConstraint
        ])
    }

    required init?(coder: NSCoder) { nil }

    private func updateConstraintsForInsets() {
        topConstraint.constant = contentInsets.top
        leadingConstraint.constant = contentInsets.left
        trailingConstraint.constant = -contentInsets.right
        bottomConstraint.constant = -contentInsets.bottom
    }
}

@MainActor
private final class XDAlertAdaptiveAlignmentLabel: UILabel {
    var alignmentMode: XDAlertTextAlignment = .adaptive
    var onTextAlignmentChange: ((NSTextAlignment) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let attributedText, bounds.width > 0 else { return }
        let desired: NSTextAlignment
        switch alignmentMode {
        case .adaptive:
            desired = XDAlertTextAlignmentResolver.alignment(
                for: attributedText,
                availableWidth: bounds.width
            )
        case .leading:
            desired = .natural
        case .center:
            desired = .center
        }
        guard textAlignment != desired else { return }
        textAlignment = desired
        onTextAlignmentChange?(desired)
    }
}

@MainActor
enum XDAlertTextAlignmentResolver {
    static func alignment(
        for attributedText: NSAttributedString,
        availableWidth: CGFloat
    ) -> NSTextAlignment {
        guard availableWidth > 0 else { return .natural }
        let singleLineWidth = attributedText.boundingRect(
            with: CGSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            ),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).width
        return ceil(singleLineWidth) <= floor(availableWidth) ? .center : .natural
    }
}

@MainActor
private final class XDAlertCheckboxView: UIControl, XDThemeable {
    let xdThemeContext: XDThemeContext
    private let titleLabel = UILabel()
    private let iconView = UIImageView()
    private let stack = UIStackView()
    private var iconWidthConstraint: NSLayoutConstraint!
    private var iconHeightConstraint: NSLayoutConstraint!
    private var minimumHeightConstraint: NSLayoutConstraint!
    private var contentLeadingConstraint: NSLayoutConstraint!
    private var contentTrailingConstraint: NSLayoutConstraint!

    override var isSelected: Bool {
        didSet { updateSelectionAppearance() }
    }

    init(configuration: XDAlertCheckboxConfiguration, themeContext: XDThemeContext) {
        self.xdThemeContext = themeContext
        super.init(frame: .zero)
        isSelected = configuration.isSelected
        isEnabled = configuration.isEnabled
        titleLabel.text = configuration.title
        accessibilityLabel = configuration.title
        isAccessibilityElement = true
        setup()
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    required init?(coder: NSCoder) { nil }

    private func setup() {
        stack.axis = .horizontal
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(titleLabel)
        iconView.contentMode = .scaleAspectFit
        titleLabel.isAccessibilityElement = false
        iconView.isAccessibilityElement = false
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        iconWidthConstraint = iconView.widthAnchor.constraint(equalToConstant: 1)
        iconHeightConstraint = iconView.heightAnchor.constraint(equalToConstant: 1)
        minimumHeightConstraint = heightAnchor.constraint(greaterThanOrEqualToConstant: 1)
        contentLeadingConstraint = stack.leadingAnchor.constraint(equalTo: leadingAnchor)
        contentTrailingConstraint = stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            contentLeadingConstraint,
            contentTrailingConstraint,
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            iconWidthConstraint,
            iconHeightConstraint,
            minimumHeightConstraint
        ])
        addTarget(self, action: #selector(toggle), for: .touchUpInside)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isUserInteractionEnabled, !isHidden, alpha > 0 else { return false }
        let minimumSize = xdThemeResolver.theme.components.alert.checkboxMinimumHitTargetSize
        let horizontalExpansion = max(0, (minimumSize - bounds.width) / 2)
        let verticalExpansion = max(0, (minimumSize - bounds.height) / 2)
        return bounds.insetBy(dx: -horizontalExpansion, dy: -verticalExpansion).contains(point)
    }

    func xdApplyTheme() {
        let resolver = xdThemeResolver
        let theme = resolver.theme.components.alert
        applyTitleStyle(theme.checkboxTextStyle, color: theme.color(for: theme.messageToken, resolver: resolver))
        titleLabel.numberOfLines = 0
        stack.spacing = theme.checkboxTitleSpacing
        contentLeadingConstraint.constant = theme.sectionContentInset
        contentTrailingConstraint.constant = -theme.sectionContentInset
        iconWidthConstraint.constant = theme.checkboxIconSize
        iconHeightConstraint.constant = theme.checkboxIconSize
        minimumHeightConstraint.constant = theme.checkboxMinimumHeight
        updateSelectionAppearance()
    }

    private func applyTitleStyle(_ style: XDFontStyle, color: UIColor) {
        guard let text = titleLabel.text else { return }
        let font = style.resolved(
            compatibleWith: traitCollection,
            fontFamily: xdThemeResolver.theme.metrics.fontFamily
        )
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .natural
        if let lineHeight = style.lineHeight {
            let scaled = lineHeight * font.pointSize / style.pointSize
            paragraph.minimumLineHeight = scaled
            paragraph.maximumLineHeight = scaled
        }
        titleLabel.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph,
                .kern: style.letterSpacing
            ]
        )
    }

    private func updateSelectionAppearance() {
        let theme = xdThemeResolver.theme.components.alert
        let assetName = isSelected ? "xd_alert_checkbox_selected" : "xd_alert_checkbox_unselected"
        let fallbackSymbolName = isSelected ? "checkmark.circle.fill" : "circle"
        if let assetImage = UIImage(
            named: assetName,
            in: XDBundle.module,
            compatibleWith: traitCollection
        ) {
            iconView.image = assetImage.withRenderingMode(.alwaysOriginal)
            iconView.tintColor = nil
        } else {
            let token = isSelected ? theme.checkboxSelectedToken : theme.checkboxUnselectedToken
            iconView.image = UIImage(systemName: fallbackSymbolName)?.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = theme.color(for: token, resolver: xdThemeResolver)
        }
        accessibilityValue = isSelected ? "已选中" : "未选中"
        accessibilityTraits = isSelected ? [.button, .selected] : [.button]
        if !isEnabled { accessibilityTraits.insert(.notEnabled) }
    }

    @objc private func toggle() {
        guard isEnabled else { return }
        isSelected.toggle()
        sendActions(for: .valueChanged)
    }
}

@MainActor
final class XDAlertTextFieldLengthController: NSObject {
    private let maximumLength: Int?

    init(maximumLength: Int?) { self.maximumLength = maximumLength }

    @objc func textDidChange(_ textField: UITextField) {
        enforceMaximumLength(in: textField)
    }

    func enforceMaximumLength(in textField: UITextField) {
        guard let maximumLength,
              textField.markedTextRange == nil,
              let text = textField.text,
              text.count > maximumLength else {
            return
        }
        let endIndex = text.index(text.startIndex, offsetBy: maximumLength)
        textField.text = String(text[..<endIndex])
        let endPosition = textField.endOfDocument
        textField.selectedTextRange = textField.textRange(from: endPosition, to: endPosition)
    }
}
