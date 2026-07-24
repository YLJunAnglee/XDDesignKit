import UIKit

@MainActor
final class XDAlertViewController: UIViewController, XDThemeable {
    let xdThemeContext: XDThemeContext
    let configuration: XDAlertConfiguration
    weak var handle: XDAlertHandle?
    var onDismissRequest: (() -> Void)?
    var onDidDismiss: (() -> Void)?

    private let dimmingView = UIView()
    private let cardView = UIView()
    private let scrollView = UIScrollView()
    private var renderer: XDAlertContentRendering!
    private var cardWidthConstraint: NSLayoutConstraint!
    private var cardHeightConstraint: NSLayoutConstraint!
    private var cardCenterYConstraint: NSLayoutConstraint!
    private var cardTopConstraint: NSLayoutConstraint!
    private var cardBottomConstraint: NSLayoutConstraint!
    private var contentTopConstraint: NSLayoutConstraint!
    private var contentLeadingConstraint: NSLayoutConstraint!
    private var contentTrailingConstraint: NSLayoutConstraint!
    private var contentBottomConstraint: NSLayoutConstraint!
    private var contentWidthConstraint: NSLayoutConstraint!
    private var keyboardOverlap: CGFloat = 0
    private var hasAnimatedPresentation = false
    private var isDismissingAlert = false
    private var hasNotifiedDismissal = false

    init(configuration: XDAlertConfiguration, themeContext: XDThemeContext) {
        self.configuration = configuration
        self.xdThemeContext = themeContext
        super.init(nibName: nil, bundle: nil)
        self.renderer = XDAlertStandardContentRenderer(
            configuration: configuration,
            themeContext: themeContext,
            onAction: { [weak self] index in self?.performAction(at: index) },
            onClose: { [weak self] in self?.dismissAlert(animated: true) }
        )
        self.renderer.onContentSizeChange = { [weak self] in
            guard let self, self.isViewLoaded else { return }
            self.view.setNeedsLayout()
        }
        modalPresentationStyle = .overFullScreen
        modalPresentationCapturesStatusBarAppearance = false
    }

    required init?(coder: NSCoder) { nil }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        registerKeyboardNotifications()
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasAnimatedPresentation else { return }
        hasAnimatedPresentation = true
        animatePresentation()
        renderer.focusPrimaryInput()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || presentingViewController == nil {
            notifyDidDismissIfNeeded()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCardLayout()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateCardLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if xdNeedsThemeUpdate(after: previousTraitCollection) { xdApplyTheme() }
    }

    var checkboxIsSelected: Bool? { renderer.checkboxIsSelected }
    var textFieldText: String? { renderer.textFieldText }

    func setActionLoading(_ isLoading: Bool, at index: Int) {
        renderer.setActionLoading(isLoading, at: index)
    }

    func dismissAlert(animated: Bool) {
        guard !isDismissingAlert else { return }
        guard presentingViewController != nil || isBeingPresented else {
            onDismissRequest?()
            return
        }

        isDismissingAlert = true
        let complete = { [weak self] in self?.dismiss(animated: false) }
        guard animated else {
            complete()
            return
        }

        let motion = XDMotion.resolved(.standard, resolver: xdThemeResolver)
        let scale = xdThemeResolver.theme.components.alert.presentationScale
        UIView.animate(
            withDuration: motion.duration,
            delay: 0,
            options: [motion.curve.animationOptions, .beginFromCurrentState],
            animations: {
                self.dimmingView.alpha = 0
                self.cardView.alpha = 0
                self.cardView.transform = CGAffineTransform(scaleX: scale, y: scale)
            },
            completion: { _ in complete() }
        )
    }

    func xdApplyTheme() {
        let resolver = xdThemeResolver
        let theme = resolver.theme.components.alert
        dimmingView.backgroundColor = theme.color(for: theme.overlayColorToken, resolver: resolver)
        dimmingView.alpha = hasAnimatedPresentation && !isDismissingAlert
            ? resolver.opacity(theme.overlayOpacityToken)
            : 0
        cardView.backgroundColor = theme.color(for: theme.cardBackgroundToken, resolver: resolver)
        cardView.layer.cornerRadius = resolver.radius(theme.cardRadiusToken)
        cardTopConstraint.constant = theme.screenVerticalInset
        cardBottomConstraint.constant = -theme.screenVerticalInset
        contentTopConstraint.constant = theme.contentVerticalInset
        contentLeadingConstraint.constant = theme.contentHorizontalInset
        contentTrailingConstraint.constant = -theme.contentHorizontalInset
        contentBottomConstraint.constant = -theme.contentVerticalInset
        contentWidthConstraint.constant = -2 * theme.contentHorizontalInset
        if !hasAnimatedPresentation {
            cardView.transform = CGAffineTransform(scaleX: theme.presentationScale, y: theme.presentationScale)
        }
        renderer.applyTheme()
        view.setNeedsLayout()
    }

    private func setupView() {
        view.backgroundColor = .clear
        view.accessibilityViewIsModal = true
        scrollView.alwaysBounceVertical = false
        scrollView.keyboardDismissMode = .interactive

        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap)))
        view.addSubview(dimmingView)
        view.addSubview(cardView)
        cardView.addSubview(scrollView)
        scrollView.addSubview(renderer.view)
        [dimmingView, cardView, scrollView, renderer.view].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        cardWidthConstraint = cardView.widthAnchor.constraint(equalToConstant: 1)
        cardHeightConstraint = cardView.heightAnchor.constraint(equalToConstant: 1)
        cardCenterYConstraint = cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        cardTopConstraint = cardView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor)
        cardBottomConstraint = cardView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor)
        contentTopConstraint = renderer.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor)
        contentLeadingConstraint = renderer.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor)
        contentTrailingConstraint = renderer.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor)
        contentBottomConstraint = renderer.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
        contentWidthConstraint = renderer.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)

        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardCenterYConstraint,
            cardWidthConstraint,
            cardHeightConstraint,
            cardTopConstraint,
            cardBottomConstraint,
            scrollView.topAnchor.constraint(equalTo: cardView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            contentTopConstraint,
            contentLeadingConstraint,
            contentTrailingConstraint,
            contentBottomConstraint,
            contentWidthConstraint
        ])
        cardView.alpha = 0
    }

    private func updateCardLayout() {
        guard isViewLoaded, view.bounds.width > 0, view.bounds.height > 0 else { return }
        let theme = xdThemeResolver.theme.components.alert
        let safeInsets = view.safeAreaInsets
        let availableWidth = max(1, view.bounds.width - safeInsets.left - safeInsets.right - 2 * theme.screenHorizontalInset)
        let cardWidth = min(theme.cardMaximumWidth, availableWidth)
        cardWidthConstraint.constant = cardWidth

        let contentWidth = max(1, cardWidth - 2 * theme.contentHorizontalInset)
        let contentHeight = renderer.view.systemLayoutSizeFitting(
            CGSize(width: contentWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let desiredHeight = contentHeight + 2 * theme.contentVerticalInset
        let availableHeight = max(
            1,
            view.bounds.height
                - safeInsets.top
                - safeInsets.bottom
                - 2 * theme.screenVerticalInset
                - keyboardOverlap
        )
        cardHeightConstraint.constant = min(desiredHeight, availableHeight)
        cardCenterYConstraint.constant = -keyboardOverlap / 2
        scrollView.isScrollEnabled = desiredHeight > availableHeight
        scrollView.showsVerticalScrollIndicator = scrollView.isScrollEnabled
    }

    private func animatePresentation() {
        let motion = XDMotion.resolved(.standard, resolver: xdThemeResolver)
        let overlayAlpha = xdThemeResolver.opacity(xdThemeResolver.theme.components.alert.overlayOpacityToken)
        UIView.animate(
            withDuration: motion.duration,
            delay: 0,
            options: [motion.curve.animationOptions, .beginFromCurrentState],
            animations: {
                self.dimmingView.alpha = overlayAlpha
                self.cardView.alpha = 1
                self.cardView.transform = .identity
            },
            completion: { _ in UIAccessibility.post(notification: .screenChanged, argument: self.cardView) }
        )
    }

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardFrameChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc private func handleKeyboardFrameChange(_ notification: Notification) {
        guard let frameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = view.convert(frameValue.cgRectValue, from: nil)
        keyboardOverlap = max(0, view.bounds.maxY - keyboardFrame.minY)
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0
        let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
            ?? UIView.AnimationCurve.easeInOut.rawValue
        let options = UIView.AnimationOptions(rawValue: UInt(curveValue << 16))
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [options, .beginFromCurrentState],
            animations: {
                self.updateCardLayout()
                self.view.layoutIfNeeded()
                self.scrollPrimaryInputIntoView()
            }
        )
    }

    private func scrollPrimaryInputIntoView() {
        guard let inputRect = renderer.primaryInputRect else { return }
        scrollView.scrollRectToVisible(renderer.view.convert(inputRect, to: scrollView), animated: false)
    }

    private func notifyDidDismissIfNeeded() {
        guard !hasNotifiedDismissal else { return }
        hasNotifiedDismissal = true
        onDidDismiss?()
    }

    @objc private func handleBackgroundTap() {
        guard configuration.allowsBackgroundDismissal else { return }
        dismissAlert(animated: true)
    }

    private func performAction(at index: Int) {
        guard configuration.actions.indices.contains(index) else { return }
        let action = configuration.actions[index]
        action.handler?(XDAlertActionContext(controller: self, actionIndex: index))
        if action.automaticallyDismisses {
            dismissAlert(animated: true)
        }
    }
}
