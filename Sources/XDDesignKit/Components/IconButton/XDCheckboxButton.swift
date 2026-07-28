import UIKit

/// A compact toggle button for completed and uncompleted states.
@MainActor
public final class XDCheckboxButton: UIControl, XDThemeable {
    /// Called after a user tap changes `isSelected`.
    public var onValueChanged: ((Bool) -> Void)?
    public private(set) var xdThemeContext: XDThemeContext

    private let imageView = UIImageView()

    public override var isSelected: Bool {
        didSet { updatePresentation() }
    }

    public override var isEnabled: Bool {
        didSet { updatePresentation() }
    }

    public init(
        isSelected: Bool = false,
        themeContext: XDThemeContext = XDThemeManager.shared.globalContext
    ) {
        self.xdThemeContext = themeContext
        super.init(frame: .zero)
        setup()
        self.isSelected = isSelected
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    public required init?(coder: NSCoder) {
        self.xdThemeContext = XDThemeManager.shared.globalContext
        super.init(coder: coder)
        setup()
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    public override var intrinsicContentSize: CGSize { imageView.image?.size ?? CGSize(width: 24, height: 24) }

    /// Rebinds a reused button to a scene-specific theme context.
    public func bindThemeContext(_ themeContext: XDThemeContext) {
        guard xdThemeContext !== themeContext else { return }
        xdUnregisterThemeUpdates()
        xdThemeContext = themeContext
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    public func xdApplyTheme() {
        updatePresentation()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if xdNeedsThemeUpdate(after: previousTraitCollection) {
            xdApplyTheme()
        }
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isEnabled, isUserInteractionEnabled, !isHidden, alpha > 0.01 else { return false }
        let minimumSize = xdThemeContext.currentTheme.components.button.minimumHitTargetSize
        let horizontalExpansion = max(0, (minimumSize.width - bounds.width) / 2)
        let verticalExpansion = max(0, (minimumSize.height - bounds.height) / 2)
        return bounds.insetBy(dx: -horizontalExpansion, dy: -verticalExpansion).contains(point)
    }

    private func setup() {
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        imageView.isAccessibilityElement = false
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        accessibilityLabel = "完成状态"
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    private func updatePresentation() {
        let assetName = isSelected ? "xd_alert_checkbox_selected" : "xd_alert_checkbox_unselected"
        let fallbackName = isSelected ? "checkmark.circle.fill" : "circle"
        if let image = UIImage(named: assetName, in: XDBundle.module, compatibleWith: traitCollection) {
            imageView.image = image.withRenderingMode(.alwaysOriginal)
            imageView.tintColor = nil
        } else {
            imageView.image = UIImage(systemName: fallbackName)?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = xdThemeResolver.color(.textPrimary)
        }
        alpha = isEnabled ? 1 : xdThemeResolver.opacity(.disabled)
        accessibilityValue = isSelected ? "已选中" : "未选中"
        accessibilityTraits = isSelected ? [.button, .selected] : [.button]
        if !isEnabled { accessibilityTraits.insert(.notEnabled) }
        invalidateIntrinsicContentSize()
    }

    @objc private func handleTap() {
        guard isEnabled else { return }
        isSelected.toggle()
        sendActions(for: .valueChanged)
        onValueChanged?(isSelected)
    }
}
