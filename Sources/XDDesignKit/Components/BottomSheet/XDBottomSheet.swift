import UIKit

/// Public entry point for generic, scene-bound UIKit bottom sheets.
@MainActor
public enum XDBottomSheet {
    @discardableResult
    public static func show(
        on presenter: UIViewController,
        contentView: UIView,
        configuration: XDBottomSheetConfiguration = .init(),
        events: XDBottomSheetEvents = .init(),
        themeContext: XDThemeContext = XDThemeManager.shared.globalContext
    ) -> XDBottomSheetHandle {
        show(
            on: presenter,
            contentViewController: XDBottomSheetContentViewController(contentView: contentView),
            configuration: configuration,
            events: events,
            themeContext: themeContext
        )
    }

    @discardableResult
    public static func show(
        on presenter: UIViewController,
        contentViewController: UIViewController,
        configuration: XDBottomSheetConfiguration = .init(),
        events: XDBottomSheetEvents = .init(),
        themeContext: XDThemeContext = XDThemeManager.shared.globalContext
    ) -> XDBottomSheetHandle {
        let controller = XDBottomSheetViewController(
            contentViewController: contentViewController,
            configuration: configuration,
            events: events,
            themeContext: themeContext
        )
        let handle = XDBottomSheetHandle(controller: controller)
        controller.handle = handle

        guard let scene = presenter.viewIfLoaded?.window?.windowScene else {
            handle.markPresentationFailed(.presenterNotAttachedToScene)
            return handle
        }
        scene.xdBottomSheetOverlayCoordinator.enqueue(controller, from: presenter)
        return handle
    }
}

@MainActor
private final class XDBottomSheetContentViewController: UIViewController {
    private let contentView: UIView

    init(contentView: UIView) {
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
