import UIKit

@MainActor
final class XDBottomSheetViewController: UIViewController, XDThemeable, UIGestureRecognizerDelegate {
    let xdThemeContext: XDThemeContext
    weak var handle: XDBottomSheetHandle?
    var onDismissRequest: (() -> Void)?
    var onDidDismiss: (() -> Void)?

    private let contentViewController: UIViewController
    private let configuration: XDBottomSheetConfiguration
    private let events: XDBottomSheetEvents
    private let dimmingView = UIView()
    private let surfaceView = UIView()
    private let panGesture = UIPanGestureRecognizer()
    private var surfaceWidthConstraint: NSLayoutConstraint!
    private var surfaceHeightConstraint: NSLayoutConstraint!
    private var surfaceBottomConstraint: NSLayoutConstraint!
    private var contentBottomConstraint: NSLayoutConstraint!
    private var keyboardOverlap: CGFloat = 0
    private weak var explicitPrimaryScrollView: UIScrollView?
    private var cachedContentHeight: CGFloat?
    private var lastMeasuredContentWidth: CGFloat?
    private var lastLayoutSignature: LayoutSignature?
    private var contentMeasurementIsInvalid = true
    /// `contentViewController.view` 首次加载时可能同步改变 preferredContentSize；
    /// 此时 BottomSheet 自身的约束尚未创建，不能提前执行布局刷新。
    private var hasCompletedViewSetup = false
    private var hasAnimatedPresentation = false
    private var isDismissingSheet = false
    private var hasNotifiedWillDismiss = false
    private var hasNotifiedDidDismiss = false
    private var pendingCompletion: (() -> Void)?
    private var panStartHeight: CGFloat = 0
    private var panTranslation: CGFloat = 0

    private struct LayoutSignature: Equatable {
        let boundsSize: CGSize
        let safeAreaInsets: UIEdgeInsets
        let keyboardOverlap: CGFloat
        let surfaceWidth: CGFloat
    }

    var isPendingPresentation = true
    var isActuallyPresented: Bool { presentingViewController != nil && !isBeingDismissed && !isDismissingSheet }
    var isInteractiveDismissalEnabled = true {
        didSet { panGesture.isEnabled = isInteractiveDismissalEnabled }
    }

    init(
        contentViewController: UIViewController,
        configuration: XDBottomSheetConfiguration,
        events: XDBottomSheetEvents,
        themeContext: XDThemeContext
    ) {
        self.contentViewController = contentViewController
        self.configuration = configuration
        self.events = events
        self.xdThemeContext = themeContext
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalPresentationCapturesStatusBarAppearance = false
        isInteractiveDismissalEnabled = configuration.allowsBackgroundDismissal || configuration.allowsSwipeDismissal
    }

    required init?(coder: NSCoder) { nil }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        registerKeyboardNotifications()
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isPendingPresentation = false
        guard !hasAnimatedPresentation else { return }
        hasAnimatedPresentation = true
        animatePresentation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard isBeingDismissed || presentingViewController?.isBeingDismissed == true else { return }
        contentViewController.view.endEditing(true)
        notifyWillDismissIfNeeded(.system)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || presentingViewController == nil { notifyDidDismissIfNeeded() }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateSurfaceLayout()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateSurfaceLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if xdNeedsThemeUpdate(after: previousTraitCollection) { xdApplyTheme() }
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        contentMeasurementIsInvalid = true
        guard hasCompletedViewSetup else { return }
        invalidateLayout(animated: configuration.animatesContentSizeChanges)
    }

    override func accessibilityPerformEscape() -> Bool {
        guard canInteractivelyDismiss else { return false }
        dismissSheet(reason: .accessibilityEscape, animated: true)
        return true
    }

    func xdApplyTheme() {
        let resolver = xdThemeResolver
        let theme = resolver.theme.components.bottomSheet
        dimmingView.backgroundColor = theme.color(for: theme.overlayColorToken, resolver: resolver)
        surfaceView.backgroundColor = theme.color(for: theme.surfaceBackgroundToken, resolver: resolver)
        surfaceView.layer.cornerRadius = resolver.radius(theme.surfaceRadiusToken)
        if hasAnimatedPresentation && !isDismissingSheet {
            dimmingView.alpha = resolver.opacity(theme.overlayOpacityToken)
        }
        contentMeasurementIsInvalid = true
        view.setNeedsLayout()
    }

    func invalidateLayout(animated: Bool) {
        guard isViewLoaded else { return }
        contentMeasurementIsInvalid = true
        let changes = { [weak self] in
            self?.updateSurfaceLayout(forceContentMeasurement: true)
            self?.view.layoutIfNeeded()
        }
        guard animated, hasAnimatedPresentation else { changes(); return }
        UIView.animate(
            withDuration: XDMotion.resolved(.standard, resolver: xdThemeResolver).duration,
            delay: 0,
            options: [.beginFromCurrentState, XDMotion.resolved(.standard, resolver: xdThemeResolver).curve.animationOptions],
            animations: changes
        )
    }

    func setPrimaryScrollView(_ scrollView: UIScrollView?) { explicitPrimaryScrollView = scrollView }

    func cancelPendingPresentation() {
        guard isPendingPresentation, presentingViewController == nil else { return }
        onDismissRequest?()
    }

    func dismissSheet(
        reason: XDBottomSheetDismissalReason,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        guard !isDismissingSheet else { return }
        guard presentingViewController != nil || isBeingPresented else {
            onDismissRequest?()
            completion?()
            return
        }
        contentViewController.view.endEditing(true)
        isDismissingSheet = true
        pendingCompletion = completion
        notifyWillDismissIfNeeded(reason)
        let finish = { [weak self] in self?.dismiss(animated: false) }
        guard animated else { finish(); return }
        let motion = XDMotion.resolved(.standard, resolver: xdThemeResolver)
        UIView.animate(
            withDuration: motion.duration,
            delay: 0,
            options: [motion.curve.animationOptions, .beginFromCurrentState],
            animations: {
                self.dimmingView.alpha = 0
                self.surfaceView.transform = CGAffineTransform(translationX: 0, y: self.surfaceView.bounds.height)
            },
            completion: { _ in finish() }
        )
    }

    private var canInteractivelyDismiss: Bool {
        isInteractiveDismissalEnabled && (configuration.allowsBackgroundDismissal || configuration.allowsSwipeDismissal)
    }

    private func setupView() {
        view.backgroundColor = .clear
        view.accessibilityViewIsModal = true
        surfaceView.clipsToBounds = true
        surfaceView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        panGesture.addTarget(self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        surfaceView.addGestureRecognizer(panGesture)
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap)))

        addChild(contentViewController)
        view.addSubview(dimmingView)
        view.addSubview(surfaceView)
        surfaceView.addSubview(contentViewController.view)
        [dimmingView, surfaceView, contentViewController.view].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        surfaceWidthConstraint = surfaceView.widthAnchor.constraint(equalToConstant: 1)
        // This remains inactive until the first fitting pass establishes the
        // real height. Activating a placeholder would conflict with content
        // that is pinned to both vertical edges.
        surfaceHeightConstraint = surfaceView.heightAnchor.constraint(equalToConstant: 0)
        surfaceBottomConstraint = surfaceView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        contentBottomConstraint = contentViewController.view.bottomAnchor.constraint(equalTo: surfaceView.safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            surfaceView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            surfaceBottomConstraint,
            surfaceWidthConstraint,
            contentViewController.view.topAnchor.constraint(equalTo: surfaceView.topAnchor),
            contentViewController.view.leadingAnchor.constraint(equalTo: surfaceView.leadingAnchor),
            contentViewController.view.trailingAnchor.constraint(equalTo: surfaceView.trailingAnchor),
            contentBottomConstraint
        ])
        contentViewController.didMove(toParent: self)
        dimmingView.alpha = 0
        surfaceView.alpha = 0
        hasCompletedViewSetup = true
    }

    private func updateSurfaceLayout(forceContentMeasurement: Bool = false) {
        guard isViewLoaded, view.bounds.width > 0, view.bounds.height > 0 else { return }
        let width = XDBottomSheetWidthResolver.resolve(
            configuration.width,
            windowWidth: view.bounds.width,
            safeAreaInsets: view.safeAreaInsets
        )
        let signature = LayoutSignature(
            boundsSize: view.bounds.size,
            safeAreaInsets: view.safeAreaInsets,
            keyboardOverlap: keyboardOverlap,
            surfaceWidth: width
        )
        let layoutEnvironmentChanged = lastLayoutSignature != signature
        guard layoutEnvironmentChanged || contentMeasurementIsInvalid || forceContentMeasurement else { return }

        surfaceWidthConstraint.constant = width
        surfaceBottomConstraint.constant = -keyboardOverlap
        let bottomSafeInset = keyboardOverlap > 0 ? 0 : view.safeAreaInsets.bottom
        let maximumHeight = max(1, view.bounds.height - view.safeAreaInsets.top - keyboardOverlap)
        var contentBottomNeedsReactivation = false
        let desiredHeight: CGFloat
        switch configuration.height.storage {
        case .content(let maximum):
            let shouldMeasure = forceContentMeasurement
                || contentMeasurementIsInvalid
                || cachedContentHeight == nil
                || lastMeasuredContentWidth != width
            if shouldMeasure {
                if contentBottomConstraint.isActive {
                    contentBottomConstraint.isActive = false
                    contentBottomNeedsReactivation = true
                }
                cachedContentHeight = measuredContentHeight(width: width)
                lastMeasuredContentWidth = width
            }
            let contentHeight = cachedContentHeight ?? 0
            desiredHeight = min(contentHeight + bottomSafeInset, maximum ?? .greatestFiniteMagnitude)
        case .fixed(let height): desiredHeight = height
        case .fraction(let value): desiredHeight = maximumHeight * value
        }
        surfaceHeightConstraint.constant = min(maximumHeight, desiredHeight)
        if !surfaceHeightConstraint.isActive {
            surfaceHeightConstraint.isActive = true
        }
        if contentBottomNeedsReactivation {
            contentBottomConstraint.isActive = true
        }
        contentMeasurementIsInvalid = false
        lastLayoutSignature = signature
    }

    private func measuredContentHeight(width: CGFloat) -> CGFloat {
        let preferred = contentViewController.preferredContentSize.height
        if preferred.isFinite, preferred > 0 { return preferred }
        let fitting = contentViewController.view.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        return max(0, fitting.isFinite ? fitting : 0)
    }

    private func animatePresentation() {
        updateSurfaceLayout()
        view.layoutIfNeeded()
        surfaceView.transform = CGAffineTransform(translationX: 0, y: surfaceView.bounds.height)
        surfaceView.alpha = 1
        let motion = XDMotion.resolved(.standard, resolver: xdThemeResolver)
        let overlayAlpha = xdThemeResolver.opacity(xdThemeResolver.theme.components.bottomSheet.overlayOpacityToken)
        UIView.animate(
            withDuration: motion.duration,
            delay: 0,
            options: [motion.curve.animationOptions, .beginFromCurrentState],
            animations: { self.dimmingView.alpha = overlayAlpha; self.surfaceView.transform = .identity },
            completion: { [weak self] _ in
                guard let self, !self.isDismissingSheet else { return }
                self.events.onDidPresent?()
                UIAccessibility.post(notification: .screenChanged, argument: self.surfaceView)
            }
        )
    }

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardFrameChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func handleKeyboardFrameChange(_ notification: Notification) {
        guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let frame = view.convert(value.cgRectValue, from: nil)
        let newOverlap = XDBottomSheetKeyboardGeometry.dockedOverlap(in: view.bounds, keyboardFrame: frame)
        let containsFirstResponder = contentViewController.view.xdContainsFirstResponder
        if newOverlap > 0, !containsFirstResponder { return }
        if newOverlap == 0, keyboardOverlap == 0, !containsFirstResponder { return }
        keyboardOverlap = newOverlap
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0
        let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int ?? UIView.AnimationCurve.easeInOut.rawValue
        UIView.animate(withDuration: duration, delay: 0, options: [UIView.AnimationOptions(rawValue: UInt(curve << 16)), .beginFromCurrentState]) {
            self.updateSurfaceLayout(); self.view.layoutIfNeeded()
        }
    }

    @objc private func handleBackgroundTap() {
        guard isInteractiveDismissalEnabled, configuration.allowsBackgroundDismissal else { return }
        dismissSheet(reason: .backgroundTap, animated: true)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isInteractiveDismissalEnabled, configuration.allowsSwipeDismissal else { return }
        let translation = gesture.translation(in: surfaceView).y
        switch gesture.state {
        case .began:
            guard canBeginSheetPan() else { gesture.isEnabled = false; gesture.isEnabled = true; return }
            panStartHeight = surfaceView.bounds.height
        case .changed:
            guard panStartHeight > 0 else { return }
            panTranslation = max(0, translation)
            let progress = min(1, panTranslation / max(1, panStartHeight))
            surfaceView.transform = CGAffineTransform(translationX: 0, y: panTranslation)
            dimmingView.alpha = xdThemeResolver.opacity(xdThemeResolver.theme.components.bottomSheet.overlayOpacityToken) * (1 - progress)
        case .ended, .cancelled, .failed:
            let velocity = gesture.velocity(in: surfaceView).y
            if panTranslation > panStartHeight * 0.30 || velocity > 1_000 {
                dismissSheet(reason: .swipe, animated: true)
            } else {
                UIView.animate(withDuration: XDMotion.resolved(.standard, resolver: xdThemeResolver).duration, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
                    self.surfaceView.transform = .identity
                    self.dimmingView.alpha = self.xdThemeResolver.opacity(self.xdThemeResolver.theme.components.bottomSheet.overlayOpacityToken)
                }
            }
            panStartHeight = 0; panTranslation = 0
        default: break
        }
    }

    private func canBeginSheetPan() -> Bool {
        if let explicitPrimaryScrollView {
            return XDBottomSheetScrollResolver.isAtTop(explicitPrimaryScrollView)
        }
        switch XDBottomSheetScrollResolver.resolve(in: contentViewController.view) {
        case .none:
            return true
        case .single(let scrollView):
            return XDBottomSheetScrollResolver.isAtTop(scrollView)
        case .ambiguous:
            return false
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === panGesture else { return true }
        let velocity = panGesture.velocity(in: surfaceView)
        return velocity.y > 0 && abs(velocity.y) > abs(velocity.x) && canBeginSheetPan()
    }

    private func notifyWillDismissIfNeeded(_ reason: XDBottomSheetDismissalReason) {
        guard !hasNotifiedWillDismiss else { return }
        hasNotifiedWillDismiss = true
        dismissalReason = reason
        events.onWillDismiss?(reason)
    }

    private var dismissalReason: XDBottomSheetDismissalReason = .system
    private func notifyDidDismissIfNeeded() {
        guard !hasNotifiedDidDismiss else { return }
        notifyWillDismissIfNeeded(.system)
        hasNotifiedDidDismiss = true
        events.onDidDismiss?(dismissalReason)
        onDidDismiss?()
        let completion = pendingCompletion
        pendingCompletion = nil
        completion?()
    }
}

private extension UIView {
    var xdContainsFirstResponder: Bool {
        if isFirstResponder { return true }
        return subviews.contains { $0.xdContainsFirstResponder }
    }
}
