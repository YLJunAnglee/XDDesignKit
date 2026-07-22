import ObjectiveC
import UIKit

@MainActor private var xdAlertOverlayCoordinatorKey: UInt8 = 0

/// Serializes alert presentation within one UIWindowScene without consulting a
/// process-global window. The scene owns this coordinator for its lifetime.
@MainActor
final class XDAlertOverlayCoordinator {
    private final class PendingPresentation {
        weak var presenter: UIViewController?
        let controller: XDAlertViewController

        init(presenter: UIViewController, controller: XDAlertViewController) {
            self.presenter = presenter
            self.controller = controller
        }
    }

    private weak var scene: UIWindowScene?
    private var activeController: XDAlertViewController?
    private var queue: [PendingPresentation] = []

    init(scene: UIWindowScene) {
        self.scene = scene
    }

    func enqueue(_ controller: XDAlertViewController, from presenter: UIViewController) {
        controller.onDismissRequest = { [weak self, weak controller] in
            guard let controller else { return }
            self?.cancel(controller)
        }
        controller.onDidDismiss = { [weak self, weak controller] in
            guard let controller else { return }
            self?.didDismiss(controller)
        }
        queue.append(PendingPresentation(presenter: presenter, controller: controller))
        presentNextIfNeeded()
    }

    private func cancel(_ controller: XDAlertViewController) {
        if activeController === controller {
            controller.dismissAlert(animated: true)
            return
        }
        queue.removeAll { $0.controller === controller }
    }

    private func didDismiss(_ controller: XDAlertViewController) {
        guard activeController === controller else { return }
        activeController = nil
        presentNextIfNeeded()
    }

    private func presentNextIfNeeded() {
        guard activeController == nil else { return }

        while !queue.isEmpty {
            let pending = queue.removeFirst()
            guard let presenter = pending.presenter,
                  presenter.viewIfLoaded?.window?.windowScene === scene else {
                pending.controller.handle?.markPresentationFailed(.presenterUnavailable)
                continue
            }
            activeController = pending.controller
            presentationHost(from: presenter).present(pending.controller, animated: false)
            verifyPresentation(of: pending.controller)
            return
        }
    }

    private func verifyPresentation(of controller: XDAlertViewController) {
        DispatchQueue.main.async { [weak self, weak controller] in
            guard let self, let controller, self.activeController === controller else { return }
            guard controller.presentingViewController == nil else { return }
            controller.handle?.markPresentationFailed(.presentationRejected)
            self.activeController = nil
            self.presentNextIfNeeded()
        }
    }

    private func presentationHost(from presenter: UIViewController) -> UIViewController {
        var host = presenter
        while let presented = host.presentedViewController, !presented.isBeingDismissed {
            host = presented
        }
        return host
    }
}

@MainActor
extension UIWindowScene {
    var xdAlertOverlayCoordinator: XDAlertOverlayCoordinator {
        if let coordinator = objc_getAssociatedObject(
            self,
            &xdAlertOverlayCoordinatorKey
        ) as? XDAlertOverlayCoordinator {
            return coordinator
        }

        let coordinator = XDAlertOverlayCoordinator(scene: self)
        objc_setAssociatedObject(
            self,
            &xdAlertOverlayCoordinatorKey,
            coordinator,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return coordinator
    }
}
