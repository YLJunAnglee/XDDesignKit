import UIKit
import XDDesignKit

/// A catalogue of every standard XDAlert form supported in the first release.
final class XDAlertDemoViewController: UIViewController, XDThemeable {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var themeUpdates: [(UITraitCollection) -> Void] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "XDAlert 体验"
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
        introduction.text = "这里集中展示第一期 XDAlert 的全部标准形态。每个入口都会实际弹出对应样式，可用主页面的主题切换验证效果。"
        bindTheme { [weak introduction] traits in
            introduction?.font = XDFont.font(.body, compatibleWith: traits)
            introduction?.textColor = XDColor.color(.textSecondary, compatibleWith: traits)
        }
        contentStack.addArrangedSubview(introduction)

        addSection("基础操作", cases: [
            ("单按钮提示", .primary, { [weak self] in self?.showSingleAction() }),
            ("双按钮确认", .primary, { [weak self] in self?.showConfirmation() }),
            ("危险操作", .outline, { [weak self] in self?.showDestructive() }),
            ("纯文字次级操作", .secondary, { [weak self] in self?.showTextAction() })
        ])
        addSection("文本对齐", cases: [
            ("默认自适应", .secondary, { [weak self] in self?.showAdaptiveTextAlignment() }),
            ("分别指定对齐方式", .secondary, { [weak self] in self?.showCustomTextAlignment() })
        ])
        addSection("带附加控件", cases: [
            ("复选框 · 单按钮", .outline, { [weak self] in self?.showCheckboxSingleAction() }),
            ("复选框 · 双按钮", .outline, { [weak self] in self?.showCheckboxConfirmation() }),
            ("输入框 · 单按钮", .secondary, { [weak self] in self?.showTextFieldSingleAction() }),
            ("输入框 · 双按钮", .secondary, { [weak self] in self?.showTextFieldConfirmation() }),
            ("多行输入框 · 自动增高", .secondary, { [weak self] in self?.showGrowingTextInput() })
        ])
        addSection("插画与关闭方式", cases: [
            ("插画 · 单按钮", .primary, { [weak self] in self?.showIllustrationSingleAction() }),
            ("插画 · 双按钮", .primary, { [weak self] in self?.showIllustrationConfirmation() }),
            ("公告 · 右上角关闭", .outline, { [weak self] in self?.showCloseButtonOnly() }),
            ("可点击蒙层关闭", .secondary, { [weak self] in self?.showBackgroundDismissible() })
        ])
    }

    private func addSection(_ title: String, cases: [(String, XDButtonStyle, () -> Void)]) {
        contentStack.addArrangedSubview(sectionTitle(title))
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

    private func showSingleAction() {
        show(title: "操作已完成", message: "你的修改已成功保存。", actions: [.primary("知道了")])
    }

    private func showConfirmation() {
        show(title: "确定删除分类吗？", message: "删除分类后，该分类下的背书文档将变成无分类。", actions: [.cancel("取消"), .primary("确定")])
    }

    private func showDestructive() {
        show(title: "确定永久删除吗？", message: "删除后无法恢复，请谨慎操作。", actions: [.cancel("取消"), .destructive("删除")])
    }

    private func showTextAction() {
        show(title: "资料尚未准备好", message: "你可以稍后再试，或向老师请求资料。", actions: [.primary("稍后再说"), .text("请求资料")])
    }

    private func showAdaptiveTextAlignment() {
        show(
            title: "提示",
            message: "这是一段宽度超过弹窗单行内容区域的说明文字，会自动使用左对齐展示。",
            actions: [.primary("知道了")]
        )
    }

    private func showCustomTextAlignment() {
        show(
            title: "标题强制左对齐",
            message: "副标题强制居中展示，即使内容换成多行也不会自动改变对齐方式。",
            actions: [.primary("知道了")],
            titleAlignment: .leading,
            messageAlignment: .center
        )
    }

    private func showCheckboxSingleAction() {
        show(title: "清理已完成内容", message: "清理后不可恢复。", accessory: .checkbox(title: "我已知晓此操作不可恢复"), actions: [.primary("清理")])
    }

    private func showCheckboxConfirmation() {
        show(title: "确定删除分类吗？", message: "删除分类后，该分类下的背书文档将变成无分类。", accessory: .checkbox(title: "同时删除分类下的背书文档", isSelected: true), actions: [.cancel("取消"), .primary("删除")])
    }

    private func showTextFieldSingleAction() {
        show(title: "新建分类", message: "请输入分类名称。", accessory: .textField(placeholder: "请输入文本", maximumLength: 20), actions: [.primary("创建")])
    }

    private func showTextFieldConfirmation() {
        show(title: "重命名分类", message: "新名称会同步展示在全部文档中。", accessory: .textField(placeholder: "请输入分类名称", text: "语文", maximumLength: 20), actions: [.cancel("取消"), .primary("保存")])
    }

    private func showGrowingTextInput() {
        show(
            title: "填写反馈",
            message: "输入框会随内容自动增高，超过四行后可在输入框内滚动。",
            accessory: .textInput(
                placeholder: "请输入反馈内容",
                maximumLength: 200,
                layout: .multiline(maximum: .lines(4)),
                onLimitReached: { limit in
                    print("Alert 输入限制：\\(limit)")
                }
            ),
            actions: [
                .cancel("取消"),
                .primary("提交") { context in
                    print(context.textFieldText ?? "")
                }
            ]
        )
    }

    private func showIllustrationSingleAction() {
        show(title: "恭喜你～", message: "已掌握挖空与分块隐藏的技巧。", illustration: celebrationIllustration, actions: [.primary("开始背书！")])
    }

    private func showIllustrationConfirmation() {
        show(title: "完成本轮学习？", message: "确认后将为你生成下一次复习计划。", illustration: celebrationIllustration, actions: [.cancel("继续学习"), .primary("确认完成")])
    }

    private func showCloseButtonOnly() {
        XDAlert.show(on: self, configuration: .init(title: "系统维护公告", message: "为提供更稳定的使用体验，服务将在今晚 01:00 至 05:00 进行系统维护。维护期间暂时无法使用，敬请谅解。", showsCloseButton: true))
    }

    private func showBackgroundDismissible() {
        XDAlert.show(on: self, configuration: .init(title: "温馨提示", message: "点击弹窗外的蒙层即可关闭。", allowsBackgroundDismissal: true))
    }

    private func show(
        title: String,
        message: String,
        illustration: XDAlertIllustration? = nil,
        accessory: XDAlertAccessory? = nil,
        actions: [XDAlertAction],
        titleAlignment: XDAlertTextAlignment = .adaptive,
        messageAlignment: XDAlertTextAlignment = .adaptive
    ) {
        XDAlert.show(
            on: self,
            configuration: .init(
                title: title,
                message: message,
                illustration: illustration,
                accessory: accessory,
                actions: actions,
                titleAlignment: titleAlignment,
                messageAlignment: messageAlignment
            )
        )
    }

    private var celebrationIllustration: XDAlertIllustration {
        XDAlertIllustration(image: UIImage(systemName: "hands.clap.fill")!, caption: "保持这个节奏，学习会越来越轻松。", accessibilityLabel: "庆祝")
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        bindTheme { [weak label] traits in
            label?.font = XDFont.font(.title2, compatibleWith: traits)
            label?.textColor = XDColor.color(.textPrimary, compatibleWith: traits)
        }
        return label
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

    private func bindTheme(_ update: @escaping (UITraitCollection) -> Void) {
        themeUpdates.append(update)
        update(traitCollection)
    }

    func xdApplyTheme() {
        view.backgroundColor = xdThemeColor(.backgroundSecondary)
        themeUpdates.forEach { $0(traitCollection) }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if xdNeedsThemeUpdate(after: previousTraitCollection) {
            xdApplyTheme()
        }
    }
}
