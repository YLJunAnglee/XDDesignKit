import UIKit
import XDDesignKit

/// Interactive catalogue for the generic container. All sheet content below is
/// ordinary UIKit owned by this demo rather than a Bottom Sheet built-in UI.
final class XDBottomSheetDemoViewController: UIViewController, XDThemeable {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var themeUpdates: [(UITraitCollection) -> Void] = []
    private var activeHandle: XDBottomSheetHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "XDBottomSheet 体验"
        setupLayout()
        buildContent()
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    private func setupLayout() {
        contentStack.axis = .vertical
        contentStack.spacing = XDSpacing.lg
        contentStack.layoutMargins = UIEdgeInsets(top: XDSpacing.lg, left: XDSpacing.md, bottom: XDSpacing.xl, right: XDSpacing.md)
        contentStack.isLayoutMarginsRelativeArrangement = true
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func buildContent() {
        let introduction = UILabel()
        introduction.numberOfLines = 0
        introduction.text = "这里验证的是通用容器能力。每个弹层内的标题、按钮、列表和页面切换都由普通 UIKit 内容自行实现。"
        bindTheme { [weak introduction] traits in
            introduction?.font = XDFont.font(.body, compatibleWith: traits)
            introduction?.textColor = XDColor.color(.textSecondary, compatibleWith: traits)
        }
        contentStack.addArrangedSubview(introduction)

        addSection("高度与宽度", cases: [
            ("内容自适应 · 全宽", .primary, { [weak self] in self?.showAdaptiveFlow() }),
            ("固定高度 · 左右留边", .secondary, { [weak self] in self?.showFixedHeight() }),
            ("比例高度 · 可滚动内容", .outline, { [weak self] in self?.showScrollableContent() })
        ])
        addSection("交互", cases: [
            ("输入框与键盘避让", .secondary, { [weak self] in self?.showKeyboardContent() }),
            ("禁止手势和蒙层关闭", .outline, { [weak self] in self?.showLockedSheet() }),
            ("全屏覆盖页 · 返回原 Sheet", .primary, { [weak self] in self?.showOverlayFlow() })
        ])
        let note = UILabel()
        note.numberOfLines = 0
        note.text = "在「内容自适应」里点击“AI 快速挖空”进入二级页面，再点“返回上层”。这模拟业务中的同一 Sheet 内页面导航。"
        bindTheme { [weak note] traits in
            note?.font = XDFont.font(.caption, compatibleWith: traits)
            note?.textColor = XDColor.color(.textTertiary, compatibleWith: traits)
        }
        contentStack.addArrangedSubview(note)
    }

    private func addSection(_ title: String, cases: [(String, XDButtonStyle, () -> Void)]) {
        let heading = UILabel()
        heading.text = title
        bindTheme { [weak heading] traits in
            heading?.font = XDFont.font(.title2, compatibleWith: traits)
            heading?.textColor = XDColor.color(.textPrimary, compatibleWith: traits)
        }
        contentStack.addArrangedSubview(heading)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = XDSpacing.sm
        for (title, style, action) in cases {
            let button = XDButton(style: style, size: .large)
            button.setTitle(title, for: .normal)
            button.setIcon(.arrowForward, placement: .trailing)
            button.onTap = action
            stack.addArrangedSubview(button)
        }
        contentStack.addArrangedSubview(card(stack))
    }

    private func showAdaptiveFlow() {
        let flow = XDBottomSheetFlowDemoController()
        activeHandle = XDBottomSheet.show(
            on: self,
            contentViewController: flow,
            events: .init(onDidDismiss: { [weak self] _ in self?.activeHandle = nil })
        )
        flow.invalidateContainerLayout = { [weak self] in self?.activeHandle?.invalidateLayout() }
        flow.dismissSheet = { [weak self] in self?.activeHandle?.dismiss() }
    }

    private func showFixedHeight() {
        let content = XDBottomSheetSimpleContentController(
            title: "固定高度",
            message: "这个页面使用 .fixed(360) 和 .horizontalInsets(20)。具体页面 UI 仍由调用方提供。"
        )
        activeHandle = XDBottomSheet.show(
            on: self,
            contentViewController: content,
            configuration: .init(height: .fixed(360), width: .horizontalInsets(20)),
            events: .init(onDidDismiss: { [weak self] _ in self?.activeHandle = nil })
        )
    }

    private func showScrollableContent() {
        let content = XDBottomSheetScrollableContentController()
        activeHandle = XDBottomSheet.show(
            on: self,
            contentViewController: content,
            configuration: .init(height: .fraction(0.65)),
            events: .init(onDidDismiss: { [weak self] _ in self?.activeHandle = nil })
        )
        activeHandle?.setPrimaryScrollView(content.scrollView)
    }

    private func showKeyboardContent() {
        let content = XDBottomSheetInputContentController()
        activeHandle = XDBottomSheet.show(
            on: self,
            contentViewController: content,
            configuration: .init(height: .content(maximum: 420)),
            events: .init(onDidDismiss: { [weak self] _ in self?.activeHandle = nil })
        )
    }

    private func showLockedSheet() {
        let content = XDBottomSheetSimpleContentController(
            title: "交互已锁定",
            message: "此 Sheet 不能点击蒙层或下拉关闭；请使用下方按钮调用 Handle.dismiss()。"
        )
        activeHandle = XDBottomSheet.show(
            on: self,
            contentViewController: content,
            configuration: .init(allowsBackgroundDismissal: false, allowsSwipeDismissal: false),
            events: .init(onDidDismiss: { [weak self] _ in self?.activeHandle = nil })
        )
        content.dismissSheet = { [weak self] in self?.activeHandle?.dismiss() }
    }

    private func showOverlayFlow() {
        let content = XDBottomSheetOverlayLauncherContentController()
        activeHandle = XDBottomSheet.show(
            on: self,
            contentViewController: content,
            events: .init(onDidDismiss: { [weak self] _ in self?.activeHandle = nil })
        )
        content.presentOverlay = { [weak self] in
            let detail = XDBottomSheetOverlayDemoViewController()
            let navigation = UINavigationController(rootViewController: detail)
            detail.closeOverlay = { [weak navigation] in
                navigation?.dismiss(animated: true)
            }
            _ = self?.activeHandle?.presentOverlay(navigation)
        }
        content.dismissSheet = { [weak self] in self?.activeHandle?.dismiss() }
    }

    private func card(_ content: UIView) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = XDRadius.md
        container.layer.borderWidth = XDBorder.regular
        bindTheme { [weak container] traits in
            container?.backgroundColor = XDColor.color(.backgroundPrimary, compatibleWith: traits)
            container?.layer.borderColor = XDColor.color(.borderPrimary, compatibleWith: traits).cgColor
        }
        container.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: XDSpacing.md),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: XDSpacing.md),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -XDSpacing.md),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -XDSpacing.md)
        ])
        return container
    }

    private func bindTheme(_ update: @escaping (UITraitCollection) -> Void) { themeUpdates.append(update); update(traitCollection) }
    func xdApplyTheme() { view.backgroundColor = xdThemeColor(.backgroundSecondary); themeUpdates.forEach { $0(traitCollection) } }
}

private class XDBottomSheetDemoContentController: UIViewController, XDThemeable {
    let stack = UIStackView()
    private var themeUpdates: [(UITraitCollection) -> Void] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        stack.axis = .vertical
        stack.spacing = XDSpacing.md
        stack.layoutMargins = UIEdgeInsets(top: XDSpacing.lg, left: XDSpacing.md, bottom: XDSpacing.lg, right: XDSpacing.md)
        stack.isLayoutMarginsRelativeArrangement = true
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    func titleLabel(_ text: String) -> UILabel {
        let label = UILabel(); label.text = text; label.numberOfLines = 0
        bindTheme { [weak label] traits in label?.font = XDFont.font(.title2, compatibleWith: traits); label?.textColor = XDColor.color(.textPrimary, compatibleWith: traits) }
        return label
    }

    func messageLabel(_ text: String) -> UILabel {
        let label = UILabel(); label.text = text; label.numberOfLines = 0
        bindTheme { [weak label] traits in label?.font = XDFont.font(.body, compatibleWith: traits); label?.textColor = XDColor.color(.textSecondary, compatibleWith: traits) }
        return label
    }

    func actionButton(_ title: String, style: XDButtonStyle = .primary, action: @escaping () -> Void) -> XDButton {
        let button = XDButton(style: style, size: .large); button.setTitle(title, for: .normal); button.onTap = action; return button
    }

    private func bindTheme(_ update: @escaping (UITraitCollection) -> Void) { themeUpdates.append(update); update(traitCollection) }
    func xdApplyTheme() { view.backgroundColor = .clear; themeUpdates.forEach { $0(traitCollection) } }
}

private final class XDBottomSheetSimpleContentController: XDBottomSheetDemoContentController {
    var dismissSheet: (() -> Void)?
    private let contentTitle: String
    private let message: String

    init(title: String, message: String) { self.contentTitle = title; self.message = message; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        stack.addArrangedSubview(titleLabel(contentTitle))
        stack.addArrangedSubview(messageLabel(message))
        stack.addArrangedSubview(actionButton("关闭", style: .outlineTransparent) { [weak self] in self?.dismissSheet?() })
    }
}

private final class XDBottomSheetOverlayLauncherContentController: XDBottomSheetDemoContentController {
    var presentOverlay: (() -> Void)?
    var dismissSheet: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        stack.addArrangedSubview(titleLabel("保留当前 Sheet"))
        stack.addArrangedSubview(messageLabel("全屏页由 Sheet 内部完整容器展示；返回后仍是同一个 Sheet 实例。"))
        stack.addArrangedSubview(actionButton("打开全屏页") { [weak self] in self?.presentOverlay?() })
        stack.addArrangedSubview(actionButton("关闭 Sheet", style: .text) { [weak self] in self?.dismissSheet?() })
    }
}

private final class XDBottomSheetOverlayDemoViewController: UIViewController, XDThemeable {
    var closeOverlay: (() -> Void)?
    private let messageLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "全屏业务页"
        messageLabel.text = "关闭后会直接恢复原 Sheet，内容和选择状态不会重建。"
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        let button = XDButton(style: .primary, size: .large)
        button.setTitle("返回原 Sheet", for: .normal)
        button.onTap = { [weak self] in self?.closeOverlay?() }
        let stack = UIStackView(arrangedSubviews: [messageLabel, button])
        stack.axis = .vertical
        stack.spacing = XDSpacing.lg
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: XDSpacing.lg),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -XDSpacing.lg),
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    func xdApplyTheme() {
        view.backgroundColor = xdThemeColor(.backgroundPrimary)
        messageLabel.font = xdThemeFont(.body)
        messageLabel.textColor = xdThemeColor(.textSecondary)
    }
}

private final class XDBottomSheetFlowDemoController: XDBottomSheetDemoContentController {
    var invalidateContainerLayout: (() -> Void)?
    var dismissSheet: (() -> Void)?
    private var isDetail = false

    override func viewDidLoad() { super.viewDidLoad(); renderPage() }

    private func renderPage() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if isDetail {
            stack.addArrangedSubview(titleLabel("AI 快速挖空"))
            stack.addArrangedSubview(messageLabel("这是同一个业务内容 Controller 内的二级页面。切换后仅调用 Handle.invalidateLayout()，不会再次展示一个 Sheet。"))
            stack.addArrangedSubview(actionButton("返回上层", style: .outline) { [weak self] in self?.isDetail = false; self?.renderPage() })
        } else {
            stack.addArrangedSubview(titleLabel("选择挖空方式"))
            stack.addArrangedSubview(messageLabel("这里模拟 BookDetailContainerController 的“挖空”入口。"))
            stack.addArrangedSubview(actionButton("AI 快速挖空") { [weak self] in self?.isDetail = true; self?.renderPage() })
            stack.addArrangedSubview(actionButton("关闭", style: .text) { [weak self] in self?.dismissSheet?() })
        }
        view.setNeedsLayout()
        invalidateContainerLayout?()
    }
}

private final class XDBottomSheetScrollableContentController: XDBottomSheetDemoContentController {
    let scrollView = UIScrollView()

    override func viewDidLoad() {
        super.viewDidLoad()
        stack.addArrangedSubview(titleLabel("可滚动内容"))
        stack.addArrangedSubview(messageLabel("先向上滚动列表；回到顶部后继续向下拖动即可关闭 Sheet。"))
        let innerStack = UIStackView(); innerStack.axis = .vertical; innerStack.spacing = XDSpacing.sm
        (1...16).forEach { index in innerStack.addArrangedSubview(messageLabel("第 \(index) 条演示内容")) }
        scrollView.addSubview(innerStack)
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            innerStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            innerStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: XDSpacing.md),
            innerStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -XDSpacing.md),
            innerStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            innerStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -2 * XDSpacing.md),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 220)
        ])
        stack.addArrangedSubview(scrollView)
    }
}

private final class XDBottomSheetInputContentController: XDBottomSheetDemoContentController {
    override func viewDidLoad() {
        super.viewDidLoad()
        stack.addArrangedSubview(titleLabel("输入框与键盘"))
        stack.addArrangedSubview(messageLabel("点击输入框，确认 Surface 会停靠在键盘顶部。"))
        let field = UITextField(); field.placeholder = "请输入一段内容"; field.borderStyle = .roundedRect
        field.font = XDFont.font(.body, compatibleWith: traitCollection)
        stack.addArrangedSubview(field)
    }
}
