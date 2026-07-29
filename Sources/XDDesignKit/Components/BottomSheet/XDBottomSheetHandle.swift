import UIKit

/// Lightweight control and observation handle for one bottom-sheet request.
@MainActor
public final class XDBottomSheetHandle {
    weak var controller: XDBottomSheetViewController?
    public private(set) var presentationFailure: XDBottomSheetPresentationFailure?

    init(controller: XDBottomSheetViewController? = nil) { self.controller = controller }

    public var isPresented: Bool { controller?.isActuallyPresented == true }
    public var isPending: Bool { controller?.isPendingPresentation == true }
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

    func markPresentationFailed(_ failure: XDBottomSheetPresentationFailure) {
        guard presentationFailure == nil else { return }
        presentationFailure = failure
        controller = nil
    }
}
