import UIKit

/// Public entry point for scene-bound, transient, fully tappable snack bars.
@MainActor
public enum XDSnackBar {
    @discardableResult
    public static func show(
        on presenter: UIViewController,
        configuration: XDSnackBarConfiguration,
        themeContext: XDThemeContext = XDThemeManager.shared.globalContext
    ) -> XDSnackBarHandle {
        let handle = XDSnackBarHandle()
        guard let window = presenter.viewIfLoaded?.window,
              let scene = window.windowScene else {
            handle.markPresentationFailed(.presenterNotAttachedToScene)
            return handle
        }

        let presentation = XDSnackBarPresentation(
            configuration: configuration,
            themeContext: themeContext,
            handle: handle
        )
        handle.presentation = presentation
        scene.xdSnackBarOverlayCoordinator.enqueue(presentation, in: window)
        return handle
    }
}
