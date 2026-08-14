import UIKit

public final class XDButton: UIButton, XDThemeable {
    public var onTap: (() -> Void)?
    public private(set) var xdThemeContext: XDThemeContext

    public private(set) var style: XDButtonStyle
    public private(set) var size: XDButtonSize

    public var iconPlacement: XDButtonIconPlacement = .leading {
        didSet {
            guard iconPlacement != oldValue else { return }
            updateContentInsets()
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// Overrides the theme's symmetric top/bottom padding for top and bottom icon layouts.
    /// Set nil to return to the current size metric.
    public var stackedContentPaddingOverride: CGFloat? {
        didSet {
            if let stackedContentPaddingOverride {
                precondition(
                    stackedContentPaddingOverride.isFinite && stackedContentPaddingOverride >= 0,
                    "Stacked button content padding must be finite and nonnegative"
                )
            }
            updateContentInsets()
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// Optional localized value announced while loading. Existing accessibility values are restored afterwards.
    public var loadingAccessibilityValue: String? {
        didSet {
            if isLoading {
                accessibilityValue = loadingAccessibilityValue ?? accessibilityValueBeforeLoading
            }
        }
    }

    public var isLoading = false {
        didSet {
            guard isLoading != oldValue else { return }
            updateLoadingPresentation()
        }
    }

    public override var isEnabled: Bool {
        didSet { updateAppearance() }
    }

    public override var isHighlighted: Bool {
        didSet { updateAppearance() }
    }

    public override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    private enum IconDefinition {
        case token(XDIconToken)
        case image(UIImage, mirrorsInRightToLeftLayout: Bool, usesTemplateRendering: Bool)
    }

    private var iconProvider: XDIconProviding
    private var iconDefinitions: [UInt: IconDefinition] = [:]
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let backgroundRenderer = XDButtonBackgroundRenderer()
    private var accessibilityValueBeforeLoading: String?
    private var addedLoadingAccessibilityTrait = false

    /// Component-owned override used by composed controls without changing the
    /// public style contract of the button itself. Returning nil preserves the
    /// style's normal border color for that state.
    var borderColorOverride: ((XDComponentState, XDThemeResolver) -> UIColor?)? {
        didSet { updateAppearance() }
    }

    public init(
        style: XDButtonStyle = .primary,
        size: XDButtonSize = .large,
        themeContext: XDThemeContext = XDThemeManager.shared.globalContext,
        iconProvider: XDIconProviding = XDSystemIconProvider.shared
    ) {
        self.style = style
        self.size = size
        self.xdThemeContext = themeContext
        self.iconProvider = iconProvider
        super.init(frame: .zero)
        setup()
    }

    public required init?(coder: NSCoder) {
        self.style = .primary
        self.size = .large
        self.xdThemeContext = XDThemeManager.shared.globalContext
        self.iconProvider = XDSystemIconProvider.shared
        super.init(coder: coder)
        setup()
    }

    public override var intrinsicContentSize: CGSize {
        let theme = xdThemeContext.currentTheme
        let metric = size.metric(in: theme)
        let measurements = contentMeasurements(metric: metric)
        let insets = resolvedContentInsets(metric: metric, theme: theme)

        return CGSize(
            width: measurements.contentSize.width + insets.left + insets.right,
            height: max(
                measurements.contentSize.height + insets.top + insets.bottom,
                metric.height
            )
        )
    }

    public func apply(style: XDButtonStyle, size: XDButtonSize? = nil) {
        self.style = style
        if let size { self.size = size }
        xdApplyTheme()
    }

    /// Native image assignment takes ownership of the specified state and clears any semantic icon definition.
    public override func setImage(_ image: UIImage?, for state: UIControl.State) {
        iconDefinitions.removeValue(forKey: state.rawValue)
        super.setImage(image, for: state)
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    /// Assigns a semantic icon and optionally changes its position relative to the title.
    public func setIcon(
        _ token: XDIconToken?,
        placement: XDButtonIconPlacement? = nil,
        for state: UIControl.State = .normal
    ) {
        if let placement { iconPlacement = placement }
        if let token {
            iconDefinitions[state.rawValue] = .token(token)
        } else {
            iconDefinitions.removeValue(forKey: state.rawValue)
        }
        resolveIcon(for: state)
    }

    /// Escape hatch for temporary or business-specific images that do not yet have an icon token.
    public func setIconImage(
        _ image: UIImage?,
        placement: XDButtonIconPlacement? = nil,
        mirrorsInRightToLeftLayout: Bool = false,
        usesTemplateRendering: Bool = true,
        for state: UIControl.State = .normal
    ) {
        if let placement { iconPlacement = placement }
        if let image {
            iconDefinitions[state.rawValue] = .image(
                image,
                mirrorsInRightToLeftLayout: mirrorsInRightToLeftLayout,
                usesTemplateRendering: usesTemplateRendering
            )
        } else {
            iconDefinitions.removeValue(forKey: state.rawValue)
        }
        resolveIcon(for: state)
    }

    /// Replaces the icon source for subsequently resolved semantic icon tokens.
    public func bindIconProvider(_ iconProvider: XDIconProviding) {
        guard self.iconProvider !== iconProvider else { return }
        self.iconProvider = iconProvider
        resolveAllIcons()
    }

    /// Rebinds decoded or reused buttons to a scene-specific theme context.
    public func bindThemeContext(_ themeContext: XDThemeContext) {
        guard xdThemeContext !== themeContext else { return }
        xdUnregisterThemeUpdates()
        xdThemeContext = themeContext
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    private func setup() {
        titleLabel?.lineBreakMode = .byTruncatingTail
        titleLabel?.numberOfLines = 1
        titleLabel?.adjustsFontForContentSizeCategory = true
        imageView?.contentMode = .scaleAspectFit
        adjustsImageWhenHighlighted = false
        updateContentInsets()
        layer.masksToBounds = true

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.isUserInteractionEnabled = false
        addSubview(loadingIndicator)

        xdRegisterThemeUpdates()
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        updateAppearance()
    }

    public func xdApplyTheme() {
        resolveAllIcons()
        updateAppearance()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    private func updateAppearance() {
        let state = componentState
        let theme = xdThemeContext.currentTheme
        let resolver = XDThemeResolver(theme: theme, traitCollection: traitCollection)
        let metric = size.metric(in: theme)
        let buttonTheme = theme.components.button
        let appearance = buttonTheme.appearance(for: style, state: state)

        backgroundRenderer.apply(
            appearance.background,
            to: self,
            resolver: resolver,
            buttonTheme: buttonTheme,
            cornerRadius: resolver.radius(metric.radiusToken)
        )
        setTitleColor(buttonTheme.color(for: buttonTheme.appearance(for: style, state: .normal).titleToken, resolver: resolver), for: .normal)
        setTitleColor(buttonTheme.color(for: buttonTheme.appearance(for: style, state: .highlighted).titleToken, resolver: resolver), for: .highlighted)
        setTitleColor(buttonTheme.color(for: buttonTheme.appearance(for: style, state: .selected).titleToken, resolver: resolver), for: .selected)
        setTitleColor(buttonTheme.color(for: buttonTheme.appearance(for: style, state: .disabled).titleToken, resolver: resolver), for: .disabled)
        tintColor = buttonTheme.color(for: appearance.iconToken, resolver: resolver)
        loadingIndicator.color = buttonTheme.color(for: appearance.iconToken, resolver: resolver)
        titleLabel?.font = resolver.font(metric.fontToken)

        contentEdgeInsets = resolvedContentInsets(metric: metric, theme: theme)
        layer.cornerRadius = resolver.radius(metric.radiusToken)
        layer.borderWidth = appearance.borderWidthToken.map(resolver.borderWidth) ?? 0
        let borderColor = borderColorOverride?(state, resolver)
            ?? appearance.borderToken.map { buttonTheme.color(for: $0, resolver: resolver) }
        layer.borderColor = borderColor?.cgColor

        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    public override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        layoutResult(in: bounds).titleFrame
    }

    public override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        layoutResult(in: bounds).iconFrame
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let result = layoutResult(in: bounds)

        titleLabel?.isHidden = iconPlacement == .only

        if isLoading {
            imageView?.isHidden = true
            loadingIndicator.frame = result.iconFrame
        } else {
            imageView?.isHidden = false
            loadingIndicator.frame = .zero
        }

        backgroundRenderer.layout(in: bounds, cornerRadius: layer.cornerRadius)
    }

    private func layoutResult(in bounds: CGRect) -> XDButtonLayoutResult {
        let theme = xdThemeContext.currentTheme
        let metric = size.metric(in: theme)
        let insets = resolvedContentInsets(metric: metric, theme: theme)
        let availableContentSize = CGSize(
            width: max(0, bounds.width - insets.left - insets.right),
            height: max(0, bounds.height - insets.top - insets.bottom)
        )
        let measurements = contentMeasurements(
            metric: metric,
            constrainedTo: availableContentSize
        )
        return XDButtonLayout.calculate(
            XDButtonLayoutInput(
                bounds: bounds,
                contentInsets: insets,
                titleSize: measurements.titleSize,
                iconSize: measurements.iconSize,
                spacing: metric.contentSpacing,
                placement: iconPlacement,
                isRightToLeft: effectiveUserInterfaceLayoutDirection == .rightToLeft,
                horizontalAlignment: contentHorizontalAlignment,
                verticalAlignment: contentVerticalAlignment
            )
        )
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if xdNeedsThemeUpdate(after: previousTraitCollection) {
            xdApplyTheme()
        } else if previousTraitCollection?.layoutDirection != traitCollection.layoutDirection {
            resolveAllIcons()
            setNeedsLayout()
        }
    }

    public override func sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        guard !isLoading else { return }
        super.sendAction(action, to: target, for: event)
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !isLoading, !isHidden, alpha > 0.01, isUserInteractionEnabled else { return false }
        let minimumSize = xdThemeContext.currentTheme.components.button.minimumHitTargetSize
        let horizontalExpansion = max(0, (minimumSize.width - bounds.width) / 2)
        let verticalExpansion = max(0, (minimumSize.height - bounds.height) / 2)
        return bounds.insetBy(dx: -horizontalExpansion, dy: -verticalExpansion).contains(point)
    }

    private var componentState: XDComponentState {
        var state: XDComponentState = .normal
        if !isEnabled { state.insert(.disabled) }
        if isHighlighted { state.insert(.highlighted) }
        if isSelected { state.insert(.selected) }
        return state
    }

    private func updateContentInsets() {
        let theme = xdThemeContext.currentTheme
        contentEdgeInsets = resolvedContentInsets(metric: size.metric(in: theme), theme: theme)
    }

    private func resolvedContentInsets(metric: XDButtonMetric, theme: XDTheme) -> UIEdgeInsets {
        var insets = size.contentInsets(in: theme)
        if iconPlacement == .top || iconPlacement == .bottom {
            let padding = stackedContentPaddingOverride ?? metric.stackedContentPadding
            insets.top = padding
            insets.bottom = padding
        }
        return insets
    }

    private func contentMeasurements(
        metric: XDButtonMetric,
        constrainedTo availableContentSize: CGSize? = nil
    ) -> (
        titleSize: CGSize,
        iconSize: CGSize,
        contentSize: CGSize
    ) {
        var titleSize: CGSize
        if iconPlacement == .only || (currentTitle == nil && currentAttributedTitle == nil) {
            titleSize = .zero
        } else {
            titleSize = titleLabel?.sizeThatFits(
                CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            ) ?? .zero
        }

        let hasIcon = isLoading || currentImage != nil
        let iconSize = hasIcon ? CGSize(width: metric.iconSize, height: metric.iconSize) : .zero
        if let availableContentSize, titleSize.width > 0 {
            let usesHorizontalLayout = iconPlacement != .top && iconPlacement != .bottom
            let reservedIconWidth = usesHorizontalLayout && iconSize.width > 0
                ? iconSize.width + metric.contentSpacing
                : 0
            titleSize.width = min(
                titleSize.width,
                max(0, availableContentSize.width - reservedIconWidth)
            )
        }
        let layout = XDButtonLayout.calculate(
            XDButtonLayoutInput(
                bounds: CGRect(origin: .zero, size: CGSize(width: 10_000, height: 10_000)),
                contentInsets: .zero,
                titleSize: titleSize,
                iconSize: iconSize,
                spacing: metric.contentSpacing,
                placement: iconPlacement,
                isRightToLeft: effectiveUserInterfaceLayoutDirection == .rightToLeft,
                horizontalAlignment: .left,
                verticalAlignment: .top
            )
        )
        return (titleSize, iconSize, layout.contentSize)
    }

    private func resolveAllIcons() {
        for rawState in iconDefinitions.keys {
            resolveIcon(for: UIControl.State(rawValue: rawState))
        }
    }

    private func resolveIcon(for state: UIControl.State) {
        guard let definition = iconDefinitions[state.rawValue] else {
            super.setImage(nil, for: state)
            invalidateIntrinsicContentSize()
            return
        }

        let resolved: XDResolvedIcon?
        switch definition {
        case let .token(token):
            resolved = iconProvider.icon(for: token, compatibleWith: traitCollection)
        case let .image(image, mirrors, usesTemplateRendering):
            resolved = XDResolvedIcon(
                image: image,
                mirrorsInRightToLeftLayout: mirrors,
                usesTemplateRendering: usesTemplateRendering
            )
        }

        var image = resolved?.image
        if resolved?.usesTemplateRendering == true {
            image = image?.withRenderingMode(.alwaysTemplate)
        }
        if resolved?.mirrorsInRightToLeftLayout == true {
            image = image?.imageFlippedForRightToLeftLayoutDirection()
        }
        super.setImage(image, for: state)
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    private func updateLoadingPresentation() {
        if isLoading {
            accessibilityValueBeforeLoading = accessibilityValue
            if let loadingAccessibilityValue { accessibilityValue = loadingAccessibilityValue }
            addedLoadingAccessibilityTrait = !accessibilityTraits.contains(.updatesFrequently)
            if addedLoadingAccessibilityTrait {
                accessibilityTraits.insert(.updatesFrequently)
            }
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
            if addedLoadingAccessibilityTrait {
                accessibilityTraits.remove(.updatesFrequently)
            }
            accessibilityValue = accessibilityValueBeforeLoading
            accessibilityValueBeforeLoading = nil
            addedLoadingAccessibilityTrait = false
        }
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    @objc private func handleTap() {
        guard !isLoading else { return }
        onTap?()
    }
}
