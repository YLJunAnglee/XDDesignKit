import UIKit

/// A compact button that opens additional actions for its surrounding content.
@MainActor
public final class XDMoreButton: UIControl, XDThemeable {
    public var onTap: (() -> Void)?
    public private(set) var xdThemeContext: XDThemeContext

    private let imageView = UIImageView()

    public override var isEnabled: Bool {
        didSet { updatePresentation() }
    }

    public init(themeContext: XDThemeContext = XDThemeManager.shared.globalContext) {
        self.xdThemeContext = themeContext
        super.init(frame: .zero)
        setup()
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
        accessibilityLabel = "更多操作"
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    private func updatePresentation() {
        if let image = UIImage(
            named: "xd_alert_action_more",
            in: XDBundle.module,
            compatibleWith: traitCollection
        ) {
            imageView.image = image.withRenderingMode(.alwaysOriginal)
            imageView.tintColor = nil
        } else {
            imageView.image = UIImage(systemName: "ellipsis")?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = xdThemeResolver.color(.textPrimary)
        }
        alpha = isEnabled ? 1 : xdThemeResolver.opacity(.disabled)
        accessibilityTraits = isEnabled ? [.button] : [.button, .notEnabled]
        invalidateIntrinsicContentSize()
    }

    @objc private func handleTap() {
        guard isEnabled else { return }
        onTap?()
    }
}
