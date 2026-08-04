import UIKit

/// Determines when a toggle commits its requested on/off value after a user tap.
public enum XDToggleSelectionBehavior: Sendable, Equatable {
    /// Commits the requested value immediately. This is the default behavior.
    case immediate
    /// Waits for the caller to confirm or cancel the requested value change.
    case requiresConfirmation
}

/// A compact binary switch with fixed 52 by 28 point visual metrics.
@MainActor
public final class XDToggle: UIControl, XDThemeable {
    /// Called whenever the toggle commits a new value.
    public var onValueChanged: ((Bool) -> Void)?
    /// Called with the requested value when confirmation is required.
    public var onValueChangeRequest: ((Bool) -> Void)?
    public let selectionBehavior: XDToggleSelectionBehavior
    /// Whether the toggle is waiting for a confirmation or cancellation from its caller.
    public private(set) var isPending = false {
        didSet { updatePresentation(animated: false) }
    }
    public private(set) var xdThemeContext: XDThemeContext

    /// The committed on/off value. Assignments update the visual state without sending `.valueChanged`.
    public var isOn: Bool {
        get { storedIsOn }
        set { setOn(newValue, animated: false) }
    }

    private let trackView = UIView()
    private let thumbView = UIView()
    private var storedIsOn: Bool

    private let visualSize = CGSize(width: 52, height: 28)
    private let thumbDiameter: CGFloat = 24
    private let thumbInset: CGFloat = 2
    private let offTrackColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)
    private let onTrackColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)

    public override var isEnabled: Bool {
        didSet { updatePresentation(animated: false) }
    }

    public init(
        isOn: Bool = false,
        selectionBehavior: XDToggleSelectionBehavior = .immediate,
        themeContext: XDThemeContext = XDThemeManager.shared.globalContext
    ) {
        self.storedIsOn = isOn
        self.selectionBehavior = selectionBehavior
        self.xdThemeContext = themeContext
        super.init(frame: .zero)
        setup()
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    public required init?(coder: NSCoder) {
        self.storedIsOn = false
        self.selectionBehavior = .immediate
        self.xdThemeContext = XDThemeManager.shared.globalContext
        super.init(coder: coder)
        setup()
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    /// The control reserves a 52 by 44 point layout and hit area; its visible track remains 52 by 28 points.
    public override var intrinsicContentSize: CGSize {
        CGSize(
            width: max(visualSize.width, xdThemeContext.currentTheme.components.button.minimumHitTargetSize.width),
            height: max(visualSize.height, xdThemeContext.currentTheme.components.button.minimumHitTargetSize.height)
        )
    }

    /// Updates the value without sending `.valueChanged` or calling `onValueChanged`.
    public func setOn(_ isOn: Bool, animated: Bool) {
        guard storedIsOn != isOn else { return }
        storedIsOn = isOn
        updatePresentation(animated: animated)
    }

    /// Rebinds a reused toggle to a scene-specific theme context.
    public func bindThemeContext(_ themeContext: XDThemeContext) {
        guard xdThemeContext !== themeContext else { return }
        xdUnregisterThemeUpdates()
        xdThemeContext = themeContext
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    /// Commits the current requested value after an asynchronous operation succeeds.
    public func resolveValueChange(to isOn: Bool) {
        guard selectionBehavior == .requiresConfirmation, isPending else { return }
        let didChange = storedIsOn != isOn
        isPending = false
        setOn(isOn, animated: true)
        if didChange {
            sendActions(for: .valueChanged)
            onValueChanged?(isOn)
        }
    }

    /// Ends the current requested value change without updating `isOn`.
    public func cancelValueChange() {
        guard selectionBehavior == .requiresConfirmation, isPending else { return }
        isPending = false
    }

    public func xdApplyTheme() {
        updatePresentation(animated: false)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if xdNeedsThemeUpdate(after: previousTraitCollection) {
            xdApplyTheme()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        trackView.frame = CGRect(
            x: (bounds.width - visualSize.width) / 2,
            y: (bounds.height - visualSize.height) / 2,
            width: visualSize.width,
            height: visualSize.height
        )
        trackView.layer.cornerRadius = visualSize.height / 2
        thumbView.frame = CGRect(
            x: storedIsOn ? visualSize.width - thumbInset - thumbDiameter : thumbInset,
            y: (visualSize.height - thumbDiameter) / 2,
            width: thumbDiameter,
            height: thumbDiameter
        )
        thumbView.layer.cornerRadius = thumbDiameter / 2
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isEnabled, !isPending, isUserInteractionEnabled, !isHidden, alpha > 0.01 else { return false }
        let minimumSize = xdThemeContext.currentTheme.components.button.minimumHitTargetSize
        let horizontalExpansion = max(0, (minimumSize.width - bounds.width) / 2)
        let verticalExpansion = max(0, (minimumSize.height - bounds.height) / 2)
        return bounds.insetBy(dx: -horizontalExpansion, dy: -verticalExpansion).contains(point)
    }

    public override func accessibilityActivate() -> Bool {
        guard isEnabled, !isPending else { return false }
        if selectionBehavior == .requiresConfirmation, onValueChangeRequest == nil { return false }
        handleTap()
        return true
    }

    private func setup() {
        trackView.isUserInteractionEnabled = false
        thumbView.isUserInteractionEnabled = false
        thumbView.backgroundColor = .white
        trackView.addSubview(thumbView)
        addSubview(trackView)
        accessibilityLabel = "开关"
        isAccessibilityElement = true
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    private func updatePresentation(animated: Bool) {
        let applyAppearance = {
            self.trackView.backgroundColor = self.storedIsOn ? self.onTrackColor : self.offTrackColor
            self.alpha = self.isEnabled && !self.isPending ? 1 : self.xdThemeResolver.opacity(.disabled)
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }

        if animated {
            let motion = XDMotion.resolved(.fast, resolver: xdThemeResolver)
            UIView.animate(
                withDuration: motion.duration,
                delay: 0,
                options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseInOut],
                animations: applyAppearance
            )
        } else {
            UIView.performWithoutAnimation(applyAppearance)
        }

        accessibilityValue = isPending ? "正在更新" : (storedIsOn ? "已开启" : "已关闭")
        accessibilityTraits = [.button]
        if !isEnabled || isPending { accessibilityTraits.insert(.notEnabled) }
        invalidateIntrinsicContentSize()
    }

    @objc private func handleTap() {
        guard isEnabled, !isPending else { return }
        let requestedValue = !storedIsOn
        switch selectionBehavior {
        case .immediate:
            setOn(requestedValue, animated: true)
            sendActions(for: .valueChanged)
            onValueChanged?(storedIsOn)
        case .requiresConfirmation:
            guard let onValueChangeRequest else { return }
            isPending = true
            onValueChangeRequest(requestedValue)
        }
    }
}
