import UIKit

/// Lightweight control and observation handle for one bottom-sheet request.
@MainActor
public final class XDBottomSheetHandle {
    weak var controller: XDBottomSheetViewController?
    public private(set) var presentationFailure: XDBottomSheetPresentationFailure?

    init(controller: XDBottomSheetViewController? = nil) { self.controller = controller }

    public var isPresented: Bool { controller?.isActuallyPresented == true }
    public var isPending: Bool { controller?.isPendingPresentation == true }
    /// Whether this Sheet is currently presenting a full-screen business overlay.
    public var isPresentingOverlay: Bool { controller?.isPresentingOverlay == true }
    public var isInteractiveDismissalEnabled: Bool {
        get { controller?.isInteractiveDismissalEnabled ?? false }
        set { controller?.isInteractiveDismissalEnabled = newValue }
    }

    public func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        controller?.dismissSheet(reason: .programmatic, animated: animated, completion: completion)
    }

    public func cancelPendingPresentation() { controller?.cancelPendingPresentation() }
    public func invalidateLayout(animated: Bool = true) { controller?.invalidateLayout(animated: animated) }
    public func setPrimaryScrollView(_ scrollView: UIScrollView?) { controller?.setPrimaryScrollView(scrollView) }

    /// Presents an arbitrary business controller above the current Sheet while
    /// preserving the Sheet's content, state, mask, and interaction lifecycle.
    ///
    /// The supplied controller is presented as `.overFullScreen`. Dismiss it
    /// normally to reveal the same Sheet instance without rebuilding it.
    ///
    /// - Returns: `true` when UIKit accepted the presentation request. Returns
    ///   `false` when the Sheet is not fully presented or is transitioning,
    ///   another overlay is active, or the supplied controller is already owned
    ///   by another hierarchy.
    @discardableResult
    public func presentOverlay(
        _ viewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) -> Bool {
        controller?.presentOverlay(viewController, animated: animated, completion: completion) ?? false
    }

    func markPresentationFailed(_ failure: XDBottomSheetPresentationFailure) {
        guard presentationFailure == nil else { return }
        presentationFailure = failure
        controller = nil
    }
}
