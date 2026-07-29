import ObjectiveC
import UIKit

@MainActor private var xdBottomSheetOverlayCoordinatorKey: UInt8 = 0

@MainActor
final class XDBottomSheetOverlayCoordinator {
    private final class PendingPresentation {
        weak var presenter: UIViewController?
        let controller: XDBottomSheetViewController
        init(presenter: UIViewController, controller: XDBottomSheetViewController) { self.presenter = presenter; self.controller = controller }
    }

    private weak var scene: UIWindowScene?
    private var activeController: XDBottomSheetViewController?
    private var queue: [PendingPresentation] = []

    init(scene: UIWindowScene) { self.scene = scene }

    func enqueue(_ controller: XDBottomSheetViewController, from presenter: UIViewController) {
        controller.onDismissRequest = { [weak self, weak controller] in guard let controller else { return }; self?.cancel(controller) }
        controller.onDidDismiss = { [weak self, weak controller] in guard let controller else { return }; self?.didDismiss(controller) }
        queue.append(PendingPresentation(presenter: presenter, controller: controller))
        presentNextIfNeeded()
    }

    private func cancel(_ controller: XDBottomSheetViewController) {
        if activeController === controller { controller.dismissSheet(reason: .programmatic, animated: true); return }
        queue.removeAll { $0.controller === controller }
    }

    private func didDismiss(_ controller: XDBottomSheetViewController) {
        guard activeController === controller else { return }
        activeController = nil
        presentNextIfNeeded()
    }

    private func presentNextIfNeeded() {
        guard activeController == nil else { return }
        while !queue.isEmpty {
            let pending = queue.removeFirst()
            guard let presenter = pending.presenter, presenter.viewIfLoaded?.window?.windowScene === scene else {
                pending.controller.handle?.markPresentationFailed(.presenterUnavailable); continue
            }
            activeController = pending.controller
            presentationHost(from: presenter).present(pending.controller, animated: false)
            DispatchQueue.main.async { [weak self, weak controller = pending.controller] in
                guard let self, let controller, self.activeController === controller, controller.presentingViewController == nil else { return }
                controller.handle?.markPresentationFailed(.presentationRejected)
                self.activeController = nil
                self.presentNextIfNeeded()
            }
            return
        }
    }

    private func presentationHost(from presenter: UIViewController) -> UIViewController {
        var host = presenter
        while let presented = host.presentedViewController, !presented.isBeingDismissed { host = presented }
        return host
    }
}

@MainActor
extension UIWindowScene {
    var xdBottomSheetOverlayCoordinator: XDBottomSheetOverlayCoordinator {
        if let value = objc_getAssociatedObject(self, &xdBottomSheetOverlayCoordinatorKey) as? XDBottomSheetOverlayCoordinator { return value }
        let coordinator = XDBottomSheetOverlayCoordinator(scene: self)
        objc_setAssociatedObject(self, &xdBottomSheetOverlayCoordinatorKey, coordinator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return coordinator
    }
}
