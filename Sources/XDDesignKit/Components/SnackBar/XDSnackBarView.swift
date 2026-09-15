import UIKit

@MainActor
final class XDSnackBarView: UIControl, XDThemeable {
    let xdThemeContext: XDThemeContext
    var onTap: (() -> Void)?

    private let configuration: XDSnackBarConfiguration
    private let contentStack = UIStackView()
    private let leadingStack = UIStackView()
    private let iconView = UIImageView()
    private let messageLabel = UILabel()
    private let annotationLabel = UILabel()
    private var minimumHeightConstraint: NSLayoutConstraint!
    private var contentTopConstraint: NSLayoutConstraint!
    private var contentBottomConstraint: NSLayoutConstraint!
    private var contentLeadingConstraint: NSLayoutConstraint!
    private var contentTrailingConstraint: NSLayoutConstraint!
    private var iconWidthConstraint: NSLayoutConstraint!
    private var iconHeightConstraint: NSLayoutConstraint!

    override var isEnabled: Bool {
        didSet { updateAppearance() }
    }

    override var isHighlighted: Bool {
        didSet { updateAppearance() }
    }

    init(configuration: XDSnackBarConfiguration, themeContext: XDThemeContext) {
        self.configuration = configuration
        self.xdThemeContext = themeContext
        super.init(frame: .zero)
        setup()
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    required init?(coder: NSCoder) { nil }

    func xdApplyTheme() {
        let resolver = xdThemeResolver
        let theme = resolver.theme.components.snackBar
        layer.cornerRadius = resolver.radius(theme.radiusToken)
        messageLabel.font = theme.font(for: theme.messageStyle, resolver: resolver)
        messageLabel.textColor = theme.color(for: theme.messageToken, resolver: resolver)
        annotationLabel.font = theme.font(for: theme.annotationStyle, resolver: resolver)
        annotationLabel.textColor = theme.color(for: theme.annotationToken, resolver: resolver)
        iconView.tintColor = theme.color(for: theme.iconToken, resolver: resolver)
        minimumHeightConstraint.constant = theme.minimumHeight
        contentTopConstraint.constant = theme.contentVerticalInset
        contentBottomConstraint.constant = -theme.contentVerticalInset
        contentLeadingConstraint.constant = theme.contentHorizontalInset
        contentTrailingConstraint.constant = -theme.contentHorizontalInset
        iconWidthConstraint.constant = theme.iconSize
        iconHeightConstraint.constant = theme.iconSize
        leadingStack.spacing = theme.iconSpacing
        contentStack.spacing = theme.annotationSpacing
        updateAppearance()
        invalidateIntrinsicContentSize()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if xdNeedsThemeUpdate(after: previousTraitCollection) {
            resolveIcon()
            xdApplyTheme()
        }
    }

    private func setup() {
        clipsToBounds = true
        iconView.contentMode = .scaleAspectFit
        iconView.isAccessibilityElement = false
        messageLabel.numberOfLines = 1
        messageLabel.lineBreakMode = .byTruncatingTail
        messageLabel.isAccessibilityElement = false
        annotationLabel.numberOfLines = 1
        annotationLabel.isAccessibilityElement = false

        leadingStack.axis = .horizontal
        leadingStack.alignment = .center
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        // 让触摸穿透到 UIControl，避免 stack 截获点击。
        leadingStack.isUserInteractionEnabled = false
        contentStack.isUserInteractionEnabled = false

        leadingStack.addArrangedSubview(iconView)
        leadingStack.addArrangedSubview(messageLabel)
        contentStack.addArrangedSubview(leadingStack)
        contentStack.addArrangedSubview(annotationLabel)
        addSubview(contentStack)

        iconView.isHidden = configuration.icon == nil
        messageLabel.text = configuration.message
        annotationLabel.text = configuration.annotation
        annotationLabel.isHidden = configuration.annotation == nil

        messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        leadingStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        annotationLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        annotationLabel.setContentHuggingPriority(.required, for: .horizontal)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        minimumHeightConstraint = heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        contentTopConstraint = contentStack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor)
        contentBottomConstraint = contentStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        contentLeadingConstraint = contentStack.leadingAnchor.constraint(equalTo: leadingAnchor)
        contentTrailingConstraint = contentStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        iconWidthConstraint = iconView.widthAnchor.constraint(equalToConstant: 24)
        iconHeightConstraint = iconView.heightAnchor.constraint(equalToConstant: 24)
        iconWidthConstraint.priority = .defaultHigh
        iconHeightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            minimumHeightConstraint,
            contentTopConstraint,
            contentBottomConstraint,
            contentLeadingConstraint,
            contentTrailingConstraint,
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconWidthConstraint,
            iconHeightConstraint
        ])

        isAccessibilityElement = true
        accessibilityTraits = .button
        updateAccessibilityLabel()
        resolveIcon()
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    private func resolveIcon() {
        guard let icon = configuration.icon else {
            iconView.image = nil
            return
        }
        if icon == .checkMark {
            let asset = UIImage(
                named: "icon_check_mark",
                in: XDBundle.module,
                compatibleWith: traitCollection
            )
            iconView.image = (asset ?? UIImage(systemName: "checkmark"))?.withRenderingMode(.alwaysTemplate)
        } else {
            iconView.image = nil
        }
    }

    private func updateAppearance() {
        let resolver = xdThemeResolver
        let theme = resolver.theme.components.snackBar
        let backgroundToken = isHighlighted ? theme.highlightedBackgroundToken : theme.backgroundToken
        backgroundColor = theme.color(for: backgroundToken, resolver: resolver)
        alpha = isEnabled ? 1 : resolver.opacity(theme.disabledOpacityToken)
        accessibilityTraits = isEnabled ? .button : [.button, .notEnabled]
    }

    private func updateAccessibilityLabel() {
        accessibilityLabel = [configuration.message, configuration.annotation]
            .compactMap { $0 }
            .joined(separator: "，")
    }

    @objc private func handleTap() {
        guard isEnabled else { return }
        onTap?()
    }
}
