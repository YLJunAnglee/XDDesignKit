import UIKit

/// The public entry point for centered alerts.
@MainActor
public enum XDAlert {
    /// Presents a standard alert from an explicit UIKit host. The host determines the UIWindowScene.
    @discardableResult
    public static func show(
        on presenter: UIViewController,
        configuration: XDAlertConfiguration,
        themeContext: XDThemeContext = XDThemeManager.shared.globalContext
    ) -> XDAlertHandle {
        let controller = XDAlertViewController(
            configuration: configuration,
            themeContext: themeContext
        )
        let handle = XDAlertHandle(controller: controller)
        controller.handle = handle

        if let scene = presenter.viewIfLoaded?.window?.windowScene {
            scene.xdAlertOverlayCoordinator.enqueue(controller, from: presenter)
        } else {
            handle.markPresentationFailed(.presenterNotAttachedToScene)
        }
        return handle
    }

    @discardableResult
    public static func show(
        on presenter: UIViewController,
        title: String? = nil,
        message: String? = nil,
        accessory: XDAlertAccessory? = nil,
        actions: [XDAlertAction],
        allowsBackgroundDismissal: Bool = false,
        themeContext: XDThemeContext = XDThemeManager.shared.globalContext
    ) -> XDAlertHandle {
        show(
            on: presenter,
            configuration: XDAlertConfiguration(
                title: title,
                message: message,
                accessory: accessory,
                actions: actions,
                allowsBackgroundDismissal: allowsBackgroundDismissal
            ),
            themeContext: themeContext
        )
    }

}
