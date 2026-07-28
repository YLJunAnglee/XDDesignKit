import UIKit

/// Determines when a checkbox commits its selected state after a user tap.
public enum XDCheckboxButtonSelectionBehavior: Sendable, Equatable {
    /// Commits the new state immediately. This is the default behavior.
    case immediate
    /// Waits for the caller to confirm or cancel the requested state change.
    case requiresConfirmation
}

/// A compact toggle button for completed and uncompleted states.
@MainActor
public final class XDCheckboxButton: UIControl, XDThemeable {
    /// Called whenever the checkbox commits a new selected state.
    public var onValueChanged: ((Bool) -> Void)?
    /// Called with the requested selected state when confirmation is required.
    public var onValueChangeRequest: ((Bool) -> Void)?
    public let selectionBehavior: XDCheckboxButtonSelectionBehavior
    /// Whether the button is waiting for a confirmation or cancellation from its caller.
    public private(set) var isPending = false {
        didSet { updatePresentation() }
    }
    public private(set) var xdThemeContext: XDThemeContext

    private let imageView = UIImageView()
    private let visualIconSize = CGSize(width: 24, height: 24)

    public override var isSelected: Bool {
        didSet { updatePresentation() }
    }

    public override var isEnabled: Bool {
        didSet { updatePresentation() }
    }

    public init(
        isSelected: Bool = false,
        selectionBehavior: XDCheckboxButtonSelectionBehavior = .immediate,
        themeContext: XDThemeContext = XDThemeManager.shared.globalContext
    ) {
        self.selectionBehavior = selectionBehavior
        self.xdThemeContext = themeContext
        super.init(frame: .zero)
        setup()
        self.isSelected = isSelected
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    public required init?(coder: NSCoder) {
        self.selectionBehavior = .immediate
        self.xdThemeContext = XDThemeManager.shared.globalContext
        super.init(coder: coder)
        setup()
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    /// The control reserves the theme's minimum hit target; its visible icon remains 24 points.
    public override var intrinsicContentSize: CGSize {
        xdThemeContext.currentTheme.components.button.minimumHitTargetSize
    }

    /// Rebinds a reused button to a scene-specific theme context.
    public func bindThemeContext(_ themeContext: XDThemeContext) {
        guard xdThemeContext !== themeContext else { return }
        xdUnregisterThemeUpdates()
        xdThemeContext = themeContext
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    /// Commits the current requested state after an asynchronous operation succeeds.
    public func resolveSelectionChange(to isSelected: Bool) {
        guard selectionBehavior == .requiresConfirmation, isPending else { return }
        let didChange = self.isSelected != isSelected
        self.isSelected = isSelected
        isPending = false
        if didChange {
            sendActions(for: .valueChanged)
            onValueChanged?(isSelected)
        }
    }

    /// Ends the current requested state change without changing `isSelected`.
    public func cancelSelectionChange() {
        guard selectionBehavior == .requiresConfirmation, isPending else { return }
        isPending = false
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
        guard isEnabled, !isPending, isUserInteractionEnabled, !isHidden, alpha > 0.01 else { return false }
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
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: visualIconSize.width),
            imageView.heightAnchor.constraint(equalToConstant: visualIconSize.height)
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
        let isInteractive = isEnabled && !isPending
        alpha = isInteractive ? 1 : xdThemeResolver.opacity(.disabled)
        accessibilityValue = isPending ? "正在更新" : (isSelected ? "已选中" : "未选中")
        accessibilityTraits = isSelected ? [.button, .selected] : [.button]
        if !isInteractive { accessibilityTraits.insert(.notEnabled) }
        invalidateIntrinsicContentSize()
    }

    @objc private func handleTap() {
        guard isEnabled, !isPending else { return }
        let requestedValue = !isSelected
        switch selectionBehavior {
        case .immediate:
            isSelected = requestedValue
            sendActions(for: .valueChanged)
            onValueChanged?(isSelected)
        case .requiresConfirmation:
            guard let onValueChangeRequest else { return }
            isPending = true
            onValueChangeRequest(requestedValue)
        }
    }
}
