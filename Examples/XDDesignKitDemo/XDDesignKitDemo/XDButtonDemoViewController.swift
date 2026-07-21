import UIKit
import XDDesignKit

final class XDButtonDemoViewController: UIViewController, XDThemeable {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let previewButton = XDButton(style: .primary, size: .large)
    private let statusLabel = UILabel()
    private let styleControl = UISegmentedControl(items: ["主", "品牌", "次", "描边", "文字", "渐变"])
    private let stateControl = UISegmentedControl(items: ["正常", "选中", "禁用", "加载"])
    private let placementControl = UISegmentedControl(items: ["前", "后", "上", "下", "纯图标"])
    private let stackedPaddingControl = UISegmentedControl(items: ["紧凑", "默认", "宽松"])
    private let directionControl = UISegmentedControl(items: ["LTR", "RTL"])
    private let themeControl = UISegmentedControl(items: ["橙色", "蓝色"])
    private let appearanceControl = UISegmentedControl(items: ["跟随系统", "浅色", "深色"])
    private var themeUpdates: [(UITraitCollection) -> Void] = []
    private var tapCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "XDButton 体验"
        setupLayout()
        buildContent()
        configurePlayground()
        xdRegisterThemeUpdates()
        xdApplyTheme()
    }

    private func setupLayout() {
        contentStack.axis = .vertical
        contentStack.spacing = XDSpacing.lg
        contentStack.layoutMargins = UIEdgeInsets(
            top: XDSpacing.lg,
            left: XDSpacing.md,
            bottom: XDSpacing.xl,
            right: XDSpacing.md
        )
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
        introduction.text = "这里是 XDButton 的独立交互测试页。可以切换主题、明暗模式、状态、图标位置和文字方向；字体大小会跟随系统的辅助功能设置。"
        bindTheme { [weak introduction] traitCollection in
            introduction?.font = XDFont.font(.body, compatibleWith: traitCollection)
            introduction?.textColor = XDColor.color(.textSecondary, compatibleWith: traitCollection)
        }
        contentStack.addArrangedSubview(introduction)

        contentStack.addArrangedSubview(sectionTitle("交互控制台"))
        contentStack.addArrangedSubview(playgroundCard())
        contentStack.addArrangedSubview(sectionTitle("常用业务形态"))
        contentStack.addArrangedSubview(commonCasesCard())
        contentStack.addArrangedSubview(sectionTitle("尺寸与图文布局"))
        contentStack.addArrangedSubview(layoutCasesCard())
        contentStack.addArrangedSubview(sectionTitle("边界状态"))
        contentStack.addArrangedSubview(boundaryCasesCard())
    }

    private func configurePlayground() {
        styleControl.selectedSegmentIndex = 0
        stateControl.selectedSegmentIndex = 0
        placementControl.selectedSegmentIndex = 0
        stackedPaddingControl.selectedSegmentIndex = 1
        directionControl.selectedSegmentIndex = 0
        themeControl.selectedSegmentIndex = XDThemeManager.shared.currentTheme.identifier == XDTheme.blueTheme.identifier ? 1 : 0
        appearanceControl.selectedSegmentIndex = 0

        styleControl.addTarget(self, action: #selector(styleChanged), for: .valueChanged)
        stateControl.addTarget(self, action: #selector(stateChanged), for: .valueChanged)
        placementControl.addTarget(self, action: #selector(placementChanged), for: .valueChanged)
        stackedPaddingControl.addTarget(self, action: #selector(stackedPaddingChanged), for: .valueChanged)
        directionControl.addTarget(self, action: #selector(directionChanged), for: .valueChanged)
        themeControl.addTarget(self, action: #selector(themeChanged), for: .valueChanged)
        appearanceControl.addTarget(self, action: #selector(appearanceChanged), for: .valueChanged)

        previewButton.setTitle("点击体验", for: .normal)
        previewButton.setIcon(.checkmarkCircle, placement: .leading)
        previewButton.loadingAccessibilityValue = "正在处理"
        previewButton.onTap = { [weak self] in
            guard let self else { return }
            tapCount += 1
            statusLabel.text = "已点击 \(tapCount) 次"
        }
        statusLabel.text = "等待点击"
    }

    private func playgroundCard() -> UIView {
        let stack = verticalStack(spacing: XDSpacing.md)
        stack.addArrangedSubview(previewButton)
        stack.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(controlRow(title: "样式", control: styleControl))
        stack.addArrangedSubview(controlRow(title: "状态", control: stateControl))
        stack.addArrangedSubview(controlRow(title: "图标位置", control: placementControl))
        stack.addArrangedSubview(controlRow(title: "上下布局留白", control: stackedPaddingControl))
        stack.addArrangedSubview(controlRow(title: "文字方向", control: directionControl))
        stack.addArrangedSubview(controlRow(title: "主题", control: themeControl))
        stack.addArrangedSubview(controlRow(title: "界面", control: appearanceControl))

        bindTheme { [weak statusLabel] traitCollection in
            statusLabel?.font = XDFont.font(.caption, compatibleWith: traitCollection)
            statusLabel?.textColor = XDColor.color(.textSecondary, compatibleWith: traitCollection)
        }
        return card(stack)
    }

    private func commonCasesCard() -> UIView {
        let stack = verticalStack(spacing: XDSpacing.sm)

        let primary = XDButton(style: .primary, size: .large)
        primary.setTitle("确认", for: .normal)

        let choose = XDButton(style: .secondary, size: .large)
        choose.setTitle("选择段落", for: .normal)
        choose.setIcon(.arrowForward, placement: .trailing)

        let actions = UIStackView()
        actions.axis = .horizontal
        actions.distribution = .fillEqually
        actions.spacing = XDSpacing.sm
        let close = XDButton(style: .outline, size: .large)
        close.setTitle("关闭", for: .normal)
        let confirm = XDButton(style: .primary, size: .large)
        confirm.setTitle("确认", for: .normal)
        actions.addArrangedSubview(close)
        actions.addArrangedSubview(confirm)

        let promotion = XDButton(style: .gradient, size: .large)
        promotion.setTitle("优惠开通", for: .normal)

        let text = XDButton(style: .text, size: .medium)
        text.setTitle("请求资料", for: .normal)
        text.setIcon(.arrowForward, placement: .trailing)

        [primary, choose, actions, promotion, text].forEach(stack.addArrangedSubview)
        return card(stack)
    }

    private func layoutCasesCard() -> UIView {
        let stack = verticalStack(spacing: XDSpacing.md)

        let sizes = UIStackView()
        sizes.axis = .horizontal
        sizes.alignment = .center
        sizes.distribution = .fillEqually
        sizes.spacing = XDSpacing.xs
        [("大", XDButtonSize.large), ("中", .medium), ("小", .small)].forEach { title, size in
            let button = XDButton(style: .primary, size: size)
            button.setTitle(title, for: .normal)
            sizes.addArrangedSubview(button)
        }

        let vertical = UIStackView()
        vertical.axis = .horizontal
        vertical.distribution = .fillEqually
        vertical.spacing = XDSpacing.sm
        let top = XDButton(style: .outline, size: .large)
        top.setTitle("完成", for: .normal)
        top.setIcon(.checkmarkCircle, placement: .top)
        let bottom = XDButton(style: .text, size: .large)
        bottom.setTitle("重录", for: .normal)
        bottom.setIcon(.refresh, placement: .bottom)
        vertical.addArrangedSubview(top)
        vertical.addArrangedSubview(bottom)

        let iconRow = UIStackView()
        iconRow.axis = .horizontal
        iconRow.alignment = .center
        iconRow.spacing = XDSpacing.md
        let iconOnly = XDButton(style: .primary, size: .small)
        iconOnly.setIcon(.checkmarkCircle, placement: .only)
        iconOnly.accessibilityLabel = "完成"
        let explanation = UILabel()
        explanation.numberOfLines = 0
        explanation.text = "纯图标：视觉尺寸较小，点击区域仍不小于 44pt"
        bindTheme { [weak explanation] traitCollection in
            explanation?.font = XDFont.font(.caption, compatibleWith: traitCollection)
            explanation?.textColor = XDColor.color(.textSecondary, compatibleWith: traitCollection)
        }
        iconRow.addArrangedSubview(iconOnly)
        iconRow.addArrangedSubview(explanation)

        [sizes, vertical, iconRow].forEach(stack.addArrangedSubview)
        return card(stack)
    }

    private func boundaryCasesCard() -> UIView {
        let stack = verticalStack(spacing: XDSpacing.sm)

        let disabled = XDButton(style: .primary, size: .large)
        disabled.setTitle("不可用状态", for: .normal)
        disabled.isEnabled = false

        let loading = XDButton(style: .primary, size: .large)
        loading.setTitle("正在提交", for: .normal)
        loading.loadingAccessibilityValue = "正在提交"
        loading.isLoading = true

        let longText = XDButton(style: .outline, size: .large)
        longText.setTitle("这是一段很长的按钮文字，用于检查受限宽度下是否正确截断", for: .normal)
        longText.setIcon(.arrowForward, placement: .trailing)

        let nativeImage = XDButton(style: .secondary, size: .large)
        nativeImage.setTitle("原生 UIImage 接管图标", for: .normal)
        nativeImage.setIcon(.arrowForward)
        nativeImage.setImage(UIImage(systemName: "star.fill"), for: .normal)

        [disabled, loading, longText, nativeImage].forEach(stack.addArrangedSubview)
        return card(stack)
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        bindTheme { [weak label] traitCollection in
            label?.font = XDFont.font(.title2, compatibleWith: traitCollection)
            label?.textColor = XDColor.color(.textPrimary, compatibleWith: traitCollection)
        }
        return label
    }

    private func controlRow(title: String, control: UIControl) -> UIView {
        let stack = verticalStack(spacing: XDSpacing.xs)
        let label = UILabel()
        label.text = title
        bindTheme { [weak label] traitCollection in
            label?.font = XDFont.font(.captionMedium, compatibleWith: traitCollection)
            label?.textColor = XDColor.color(.textPrimary, compatibleWith: traitCollection)
        }
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(control)
        return stack
    }

    private func verticalStack(spacing: CGFloat) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = spacing
        return stack
    }

    private func card(_ content: UIView) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = XDRadius.md
        container.layer.borderWidth = XDBorder.regular
        bindTheme { [weak container] traitCollection in
            container?.backgroundColor = XDColor.color(.backgroundPrimary, compatibleWith: traitCollection)
            container?.layer.borderColor = XDColor.color(.borderPrimary, compatibleWith: traitCollection).cgColor
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

    @objc private func styleChanged() {
        let styles: [XDButtonStyle] = [.primary, .brand, .secondary, .outline, .text, .gradient]
        previewButton.apply(style: styles[styleControl.selectedSegmentIndex])
    }

    @objc private func stateChanged() {
        previewButton.isEnabled = true
        previewButton.isSelected = false
        previewButton.isLoading = false
        switch stateControl.selectedSegmentIndex {
        case 1: previewButton.isSelected = true
        case 2: previewButton.isEnabled = false
        case 3: previewButton.isLoading = true
        default: break
        }
    }

    @objc private func placementChanged() {
        let placements: [XDButtonIconPlacement] = [.leading, .trailing, .top, .bottom, .only]
        let placement = placements[placementControl.selectedSegmentIndex]
        previewButton.setIcon(.checkmarkCircle, placement: placement)
        previewButton.accessibilityLabel = placement == .only ? "完成" : nil
    }

    @objc private func stackedPaddingChanged() {
        let paddings: [CGFloat?] = [4, nil, 20]
        previewButton.stackedContentPaddingOverride = paddings[stackedPaddingControl.selectedSegmentIndex]
    }

    @objc private func directionChanged() {
        previewButton.semanticContentAttribute = directionControl.selectedSegmentIndex == 1
            ? .forceRightToLeft
            : .forceLeftToRight
        previewButton.setNeedsLayout()
    }

    @objc private func themeChanged() {
        let theme: XDTheme = themeControl.selectedSegmentIndex == 1 ? .blueTheme : .defaultTheme
        do {
            try XDThemeManager.shared.apply(theme)
        } catch {
            assertionFailure("Built-in theme is invalid: \(error)")
        }
    }

    @objc private func appearanceChanged() {
        let styles: [UIUserInterfaceStyle] = [.unspecified, .light, .dark]
        overrideUserInterfaceStyle = styles[appearanceControl.selectedSegmentIndex]
    }
}
