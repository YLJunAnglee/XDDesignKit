import ObjectiveC
import UIKit

@MainActor private var xdSnackBarOverlayCoordinatorKey: UInt8 = 0

/// Serializes snack bars inside one UIWindowScene while leaving the underlying interface interactive.
@MainActor
final class XDSnackBarOverlayCoordinator {
    private final class PendingPresentation {
        weak var window: UIWindow?
        let presentation: XDSnackBarPresentation

        init(window: UIWindow, presentation: XDSnackBarPresentation) {
            self.window = window
            self.presentation = presentation
        }
    }

    private weak var scene: UIWindowScene?
    private var activePresentation: XDSnackBarPresentation?
    private var queue: [PendingPresentation] = []

    init(scene: UIWindowScene) {
        self.scene = scene
    }

    func enqueue(_ presentation: XDSnackBarPresentation, in window: UIWindow) {
        presentation.onDismissRequest = { [weak self, weak presentation] reason, animated in
            guard let presentation else { return }
            self?.dismiss(presentation, reason: reason, animated: animated)
        }
        presentation.onCancelPendingRequest = { [weak self, weak presentation] in
            guard let presentation else { return }
            self?.cancelPending(presentation)
        }
        presentation.onDidFinish = { [weak self, weak presentation] in
            guard let presentation else { return }
            self?.didFinish(presentation)
        }
        queue.append(PendingPresentation(window: window, presentation: presentation))
        presentNextIfNeeded()
    }

    private func dismiss(
        _ presentation: XDSnackBarPresentation,
        reason: XDSnackBarDismissalReason,
        animated: Bool
    ) {
        guard activePresentation === presentation else {
            cancelPending(presentation)
            return
        }
        presentation.performDismissal(reason: reason, animated: animated)
    }

    private func cancelPending(_ presentation: XDSnackBarPresentation) {
        guard activePresentation !== presentation else { return }
        let wasQueued = queue.contains { $0.presentation === presentation }
        queue.removeAll { $0.presentation === presentation }
        if wasQueued { presentation.markPendingCancellationCompleted() }
    }

    private func didFinish(_ presentation: XDSnackBarPresentation) {
        guard activePresentation === presentation else { return }
        activePresentation = nil
        presentNextIfNeeded()
    }

    private func presentNextIfNeeded() {
        guard activePresentation == nil else { return }
        while !queue.isEmpty {
            let pending = queue.removeFirst()
            guard let window = pending.window, window.windowScene === scene else {
                pending.presentation.markPresentationFailed(.presenterUnavailable)
                continue
            }
            activePresentation = pending.presentation
            pending.presentation.present(in: window)
            return
        }
    }
}

@MainActor
extension UIWindowScene {
    var xdSnackBarOverlayCoordinator: XDSnackBarOverlayCoordinator {
        if let coordinator = objc_getAssociatedObject(
            self,
            &xdSnackBarOverlayCoordinatorKey
        ) as? XDSnackBarOverlayCoordinator {
            return coordinator
        }

        let coordinator = XDSnackBarOverlayCoordinator(scene: self)
        objc_setAssociatedObject(
            self,
            &xdSnackBarOverlayCoordinatorKey,
            coordinator,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return coordinator
    }
}

@MainActor
final class XDSnackBarPresentation: NSObject {
    private enum State { case pending, presenting, presented, dismissing, finished }

    private let configuration: XDSnackBarConfiguration
    private let themeContext: XDThemeContext
    private weak var handle: XDSnackBarHandle?
    private weak var window: UIWindow?
    private var overlayView: XDSnackBarPassthroughView?
    private var snackBarView: XDSnackBarView?
    private var timer: Timer?
    private var state: State = .pending

    var onDismissRequest: ((XDSnackBarDismissalReason, Bool) -> Void)?
    var onCancelPendingRequest: (() -> Void)?
    var onDidFinish: (() -> Void)?

    var isPending: Bool { state == .pending }
    var isPresented: Bool { state == .presenting || state == .presented }

    init(
        configuration: XDSnackBarConfiguration,
        themeContext: XDThemeContext,
        handle: XDSnackBarHandle
    ) {
        self.configuration = configuration
        self.themeContext = themeContext
        self.handle = handle
    }

    func present(in window: UIWindow) {
        guard state == .pending else { return }
        state = .presenting
        self.window = window

        let overlay = XDSnackBarPassthroughView()
        let snackBar = XDSnackBarView(configuration: configuration, themeContext: themeContext)
        snackBar.onTap = { [weak self] in self?.handleTap() }
        overlay.addSubview(snackBar)
        window.addSubview(overlay)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        snackBar.translatesAutoresizingMaskIntoConstraints = false

        let theme = themeContext.currentTheme.components.snackBar
        let preferredWidth = snackBar.widthAnchor.constraint(
            equalTo: overlay.safeAreaLayoutGuide.widthAnchor,
            constant: -2 * theme.screenHorizontalInset
        )
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: window.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: window.bottomAnchor),
            snackBar.leadingAnchor.constraint(
                greaterThanOrEqualTo: overlay.safeAreaLayoutGuide.leadingAnchor,
                constant: theme.screenHorizontalInset
            ),
            snackBar.trailingAnchor.constraint(
                lessThanOrEqualTo: overlay.safeAreaLayoutGuide.trailingAnchor,
                constant: -theme.screenHorizontalInset
            ),
            snackBar.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            snackBar.widthAnchor.constraint(lessThanOrEqualToConstant: theme.maximumWidth),
            preferredWidth,
            snackBar.bottomAnchor.constraint(
                equalTo: overlay.safeAreaLayoutGuide.bottomAnchor,
                constant: -(configuration.bottomInset ?? theme.defaultBottomInset)
            )
        ])
        overlay.layoutIfNeeded()
        self.overlayView = overlay
        self.snackBarView = snackBar

        let resolver = themeContext.resolver(compatibleWith: snackBar.traitCollection)
        let motion = XDMotion.resolved(theme.motionToken, resolver: resolver)
        snackBar.alpha = 0
        snackBar.transform = CGAffineTransform(translationX: 0, y: theme.presentationOffset)
        UIView.animate(
            withDuration: motion.duration,
            delay: 0,
            options: [.beginFromCurrentState, motion.curve.animationOptions],
            animations: {
                snackBar.alpha = 1
                snackBar.transform = .identity
            },
            completion: { [weak self] _ in
                guard let self, self.state == .presenting else { return }
                self.state = .presented
                self.startTimerIfNeeded()
                UIAccessibility.post(notification: .announcement, argument: snackBar.accessibilityLabel)
            }
        )
    }

    func dismiss(reason: XDSnackBarDismissalReason, animated: Bool) {
        switch state {
        case .pending:
            onDismissRequest?(reason, animated)
        case .presenting, .presented:
            onDismissRequest?(reason, animated)
        case .dismissing, .finished:
            break
        }
    }

    func cancelPendingPresentation() {
        guard state == .pending else { return }
        onCancelPendingRequest?()
    }

    func performDismissal(reason: XDSnackBarDismissalReason, animated: Bool) {
        guard state == .presenting || state == .presented else { return }
        state = .dismissing
        timer?.invalidate()
        timer = nil

        guard let snackBar = snackBarView else {
            finish()
            return
        }
        let completion = { [weak self] in
            self?.overlayView?.removeFromSuperview()
            self?.finish()
        }
        guard animated else {
            completion()
            return
        }

        let theme = themeContext.currentTheme.components.snackBar
        let resolver = themeContext.resolver(compatibleWith: snackBar.traitCollection)
        let motion = XDMotion.resolved(theme.motionToken, resolver: resolver)
        UIView.animate(
            withDuration: motion.duration,
            delay: 0,
            options: [.beginFromCurrentState, motion.curve.animationOptions],
            animations: {
                snackBar.alpha = 0
                snackBar.transform = CGAffineTransform(translationX: 0, y: theme.presentationOffset)
            },
            completion: { _ in completion() }
        )
    }

    func markPendingCancellationCompleted() {
        guard state == .pending else { return }
        finish()
    }

    func markPresentationFailed(_ failure: XDSnackBarPresentationFailure) {
        guard state == .pending else { return }
        state = .finished
        handle?.markPresentationFailed(failure)
        clearCallbacks()
    }

    private func handleTap() {
        guard state == .presenting || state == .presented else { return }
        configuration.onTap(XDSnackBarActionContext(presentation: self))
        if configuration.automaticallyDismissesOnTap {
            dismiss(reason: .tap, animated: true)
        }
    }

    private func startTimerIfNeeded() {
        guard let duration = configuration.duration else { return }
        let timer = Timer(timeInterval: duration, target: self, selector: #selector(handleTimeout), userInfo: nil, repeats: false)
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    @objc private func handleTimeout() {
        dismiss(reason: .timeout, animated: true)
    }

    private func finish() {
        guard state != .finished else { return }
        state = .finished
        timer?.invalidate()
        timer = nil
        overlayView?.removeFromSuperview()
        overlayView = nil
        snackBarView = nil
        window = nil
        onDidFinish?()
        clearCallbacks()
    }

    private func clearCallbacks() {
        onDismissRequest = nil
        onCancelPendingRequest = nil
        onDidFinish = nil
    }
}

private final class XDSnackBarPassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        return hitView === self ? nil : hitView
    }
}
