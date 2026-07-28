import UIKit

/// Internal seam for future custom content. Presentation never depends on standard-content details.
@MainActor
protocol XDAlertContentRendering: AnyObject {
    var view: UIView { get }
    var checkboxIsSelected: Bool? { get }
    var textFieldText: String? { get }
    var primaryInputCaretRect: CGRect? { get }
    var onContentSizeChange: (() -> Void)? { get set }
    func applyTheme()
    func setActionLoading(_ isLoading: Bool, at index: Int)
    func focusPrimaryInput()
}

@MainActor
final class XDAlertStandardContentRenderer: XDAlertContentRendering {
    let contentView: XDAlertStandardContentView
    var view: UIView { contentView }
    var checkboxIsSelected: Bool? { contentView.checkboxIsSelected }
    var textFieldText: String? { contentView.textFieldText }
    var primaryInputCaretRect: CGRect? { contentView.primaryInputCaretRect }
    var onContentSizeChange: (() -> Void)? {
        get { contentView.onContentSizeChange }
        set { contentView.onContentSizeChange = newValue }
    }

    init(
        configuration: XDAlertConfiguration,
        themeContext: XDThemeContext,
        onAction: @escaping (Int) -> Void,
        onClose: @escaping () -> Void
    ) {
        contentView = XDAlertStandardContentView(
            configuration: configuration,
            themeContext: themeContext,
            onAction: onAction,
            onClose: onClose
        )
    }

    func applyTheme() { contentView.xdApplyTheme() }
    func setActionLoading(_ isLoading: Bool, at index: Int) {
        contentView.setActionLoading(isLoading, at: index)
    }

    func focusPrimaryInput() { contentView.focusPrimaryInput() }
}
