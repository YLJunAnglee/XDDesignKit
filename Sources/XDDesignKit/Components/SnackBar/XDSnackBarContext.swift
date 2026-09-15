import UIKit

/// A lightweight reference to one visible or queued snack bar.
@MainActor
public final class XDSnackBarHandle {
    weak var presentation: XDSnackBarPresentation?
    public private(set) var presentationFailure: XDSnackBarPresentationFailure?

    public var isPresented: Bool { presentation?.isPresented == true }
    public var isPending: Bool { presentation?.isPending == true }

    public func dismiss(animated: Bool = true) {
        presentation?.dismiss(reason: .programmatic, animated: animated)
    }

    public func cancelPendingPresentation() {
        presentation?.cancelPendingPresentation()
    }

    func markPresentationFailed(_ failure: XDSnackBarPresentationFailure) {
        guard presentationFailure == nil else { return }
        presentationFailure = failure
        presentation = nil
    }
}

/// Controls available while handling a tap on the entire snack-bar surface.
@MainActor
public final class XDSnackBarActionContext {
    private weak var presentation: XDSnackBarPresentation?

    init(presentation: XDSnackBarPresentation) {
        self.presentation = presentation
    }

    public func dismiss(animated: Bool = true) {
        presentation?.dismiss(reason: .tap, animated: animated)
    }
}
