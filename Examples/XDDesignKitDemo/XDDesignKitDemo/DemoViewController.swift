import UIKit
import XDDesignKit

final class DemoViewController: UIViewController, XDThemeable {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let themeControl = UISegmentedControl(items: ["Orange", "Blue"])
    private var themeUpdates: [(UITraitCollection) -> Void] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "XDDesignKit"
        setupLayout()
        buildDemo()
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

    private func buildDemo() {
        contentStack.addArrangedSubview(sectionTitle("Theme"))
        contentStack.addArrangedSubview(themeSelector())

        contentStack.addArrangedSubview(sectionTitle("Colors"))
        contentStack.addArrangedSubview(colorGrid())

        contentStack.addArrangedSubview(sectionTitle("Typography"))
        contentStack.addArrangedSubview(fontSamples())

        contentStack.addArrangedSubview(sectionTitle("Buttons"))
        contentStack.addArrangedSubview(buttonSamples())

        contentStack.addArrangedSubview(sectionTitle("Toggles"))
        contentStack.addArrangedSubview(toggleSamples())

        contentStack.addArrangedSubview(sectionTitle("Alerts"))
        contentStack.addArrangedSubview(alertSamples())

        contentStack.addArrangedSubview(sectionTitle("Bottom Sheets"))
        contentStack.addArrangedSubview(bottomSheetSamples())
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        bindTheme { traitCollection in
            label.font = XDFont.font(.title2, compatibleWith: traitCollection)
            label.textColor = XDColor.color(.textPrimary, compatibleWith: traitCollection)
        }
        return label
    }

    private func themeSelector() -> UIView {
        themeControl.selectedSegmentIndex = XDThemeManager.shared.currentTheme.identifier == XDTheme.blueTheme.identifier ? 1 : 0
        themeControl.addTarget(self, action: #selector(handleThemeControlChanged), for: .valueChanged)
        return card(themeControl)
    }

    private func colorGrid() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = XDSpacing.sm

        let rows: [(String, XDColorToken)] = [
            ("brandPrimary", .brandPrimary),
            ("textPrimary", .textPrimary),
            ("textSecondary", .textSecondary),
            ("backgroundPrimary", .backgroundPrimary),
            ("backgroundSecondary", .backgroundSecondary),
            ("borderPrimary", .borderPrimary)
        ]

        rows.forEach { name, token in
            stack.addArrangedSubview(colorRow(name: name, token: token))
        }

        return card(stack)
    }

    private func colorRow(name: String, token: XDColorToken) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = XDSpacing.sm

        let swatch = UIView()
        swatch.layer.cornerRadius = XDRadius.sm
        swatch.layer.borderWidth = XDBorder.regular
        swatch.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            swatch.widthAnchor.constraint(equalToConstant: 36),
            swatch.heightAnchor.constraint(equalToConstant: 36)
        ])

        let label = UILabel()
        label.text = name
        bindTheme { traitCollection in
            label.font = XDFont.font(.body, compatibleWith: traitCollection)
            swatch.backgroundColor = XDColor.color(token, compatibleWith: traitCollection)
            swatch.layer.borderColor = XDColor.color(.borderPrimary, compatibleWith: traitCollection).cgColor
            label.textColor = XDColor.color(.textPrimary, compatibleWith: traitCollection)
        }

        row.addArrangedSubview(swatch)
        row.addArrangedSubview(label)
        return row
    }

    private func fontSamples() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = XDSpacing.sm

        let samples: [(String, XDFontToken)] = [
            ("Title 1 / 20 Semibold", .title1),
            ("Title 2 / 18 Semibold", .title2),
            ("Title 3 / 16 Semibold", .title3),
            ("Body / 14 Regular", .body),
            ("Caption / 12 Regular", .caption)
        ]

        samples.forEach { text, token in
            let label = UILabel()
            label.text = text
            bindTheme { traitCollection in
                label.font = XDFont.font(token, compatibleWith: traitCollection)
                label.textColor = XDColor.color(.textPrimary, compatibleWith: traitCollection)
            }
            stack.addArrangedSubview(label)
        }

        [
            ("Fixed / 16 PingFang Regular", XDFont.fixed.regular(16)),
            ("Fixed / 18 PingFang Medium", XDFont.fixed.medium(18)),
            ("Fixed / 20 PingFang Semibold", XDFont.fixed.semibold(20))
        ].forEach { text, font in
            let label = UILabel()
            label.text = text
            label.font = font
            bindTheme { traitCollection in
                label.textColor = XDColor.color(.textPrimary, compatibleWith: traitCollection)
            }
            stack.addArrangedSubview(label)
        }

        return card(stack)
    }

    private func buttonSamples() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = XDSpacing.sm

        let openButtonDemo = XDButton(style: .gradient, size: .large)
        openButtonDemo.setTitle("打开 XDButton 独立体验页", for: .normal)
        openButtonDemo.setIcon(.arrowForward, placement: .trailing)
        openButtonDemo.onTap = { [weak self] in
            self?.navigationController?.pushViewController(XDButtonDemoViewController(), animated: true)
        }
        stack.addArrangedSubview(openButtonDemo)

        stack.addArrangedSubview(buttonGroupTitle("Style × State"))
        let styles: [(String, XDButtonStyle)] = [
            ("Primary", .primary),
            ("Brand", .brand),
            ("Secondary", .secondary),
            ("Outline", .outline),
            ("Text", .text),
            ("Gradient", .gradient)
        ]
        styles.forEach { name, style in
            stack.addArrangedSubview(buttonGroupTitle(name))
            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = XDSpacing.xs

            let normal = XDButton(style: style, size: .small)
            normal.setTitle("Normal", for: .normal)
            let highlighted = XDButton(style: style, size: .small)
            highlighted.setTitle("Pressed", for: .normal)
            highlighted.isHighlighted = true
            let selected = XDButton(style: style, size: .small)
            selected.setTitle("Selected", for: .normal)
            selected.isSelected = true
            let disabled = XDButton(style: style, size: .small)
            disabled.setTitle("Disabled", for: .normal)
            disabled.isEnabled = false

            [normal, highlighted, selected, disabled].forEach(row.addArrangedSubview)
            stack.addArrangedSubview(row)
        }

        stack.addArrangedSubview(buttonGroupTitle("Sizes"))
        let sizes = UIStackView()
        sizes.axis = .horizontal
        sizes.alignment = .center
        sizes.distribution = .fillEqually
        sizes.spacing = XDSpacing.xs
        [XDButtonSize.large, .medium, .small].forEach { size in
            let button = XDButton(style: .primary, size: size)
            button.setTitle(size.rawValue.capitalized, for: .normal)
            sizes.addArrangedSubview(button)
        }
        stack.addArrangedSubview(sizes)

        stack.addArrangedSubview(buttonGroupTitle("Icon Placement"))
        let leading = XDButton(style: .primary, size: .large)
        leading.setTitle("Leading Icon", for: .normal)
        leading.setIcon(.checkmarkCircle, placement: .leading)

        let trailing = XDButton(style: .secondary, size: .large)
        trailing.setTitle("Choose Section", for: .normal)
        trailing.setIcon(.arrowForward, placement: .trailing)

        let top = XDButton(style: .outline, size: .large)
        top.setTitle("Complete", for: .normal)
        top.setIcon(.checkmarkCircle, placement: .top)

        let bottom = XDButton(style: .text, size: .large)
        bottom.setTitle("Refresh", for: .normal)
        bottom.setIcon(.refresh, placement: .bottom)

        [leading, trailing, top, bottom].forEach(stack.addArrangedSubview)

        let iconRow = UIStackView()
        iconRow.axis = .horizontal
        iconRow.alignment = .center
        iconRow.spacing = XDSpacing.md
        let iconOnly = XDButton(style: .primary, size: .small)
        iconOnly.setIcon(.checkmarkCircle, placement: .only)
        iconOnly.accessibilityLabel = "Complete"
        iconRow.addArrangedSubview(iconOnly)
        iconRow.addArrangedSubview(buttonGroupTitle("Icon-only keeps a 44pt hit target"))
        stack.addArrangedSubview(iconRow)

        stack.addArrangedSubview(buttonGroupTitle("Loading / Long Text / RTL"))
        let loading = XDButton(style: .primary, size: .large)
        loading.setTitle("Submitting", for: .normal)
        loading.loadingAccessibilityValue = "Loading"
        loading.isLoading = true

        let longText = XDButton(style: .outline, size: .large)
        longText.setTitle("A very long button title that demonstrates truncation", for: .normal)

        let rightToLeft = XDButton(style: .secondary, size: .large)
        rightToLeft.setTitle("RTL Leading Icon", for: .normal)
        rightToLeft.setIcon(.arrowForward, placement: .leading)
        rightToLeft.semanticContentAttribute = .forceRightToLeft

        [loading, longText, rightToLeft].forEach(stack.addArrangedSubview)

        return card(stack)
    }

    private func alertSamples() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = XDSpacing.sm

        let openAlertDemo = XDButton(style: .primary, size: .large)
        openAlertDemo.setTitle("打开 XDAlert 独立体验页", for: .normal)
        openAlertDemo.setIcon(.arrowForward, placement: .trailing)
        openAlertDemo.onTap = { [weak self] in
            self?.navigationController?.pushViewController(XDAlertDemoViewController(), animated: true)
        }
        stack.addArrangedSubview(openAlertDemo)
        return card(stack)
    }

    private func toggleSamples() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = XDSpacing.sm

        let off = XDToggle()
        let on = XDToggle(isOn: true)
        let disabled = XDToggle(isOn: true)
        disabled.isEnabled = false
        let confirmation = XDToggle(selectionBehavior: .requiresConfirmation)
        confirmation.onValueChangeRequest = { [weak confirmation] requestedValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                confirmation?.resolveValueChange(to: requestedValue)
            }
        }

        stack.addArrangedSubview(toggleRow(title: "关闭", detail: "点击后立即切换", toggle: off))
        stack.addArrangedSubview(toggleRow(title: "开启", detail: "默认开启状态", toggle: on))
        stack.addArrangedSubview(toggleRow(title: "禁用", detail: "开启且不可操作", toggle: disabled))
        stack.addArrangedSubview(toggleRow(title: "确认模式", detail: "点击后模拟 0.6 秒接口确认", toggle: confirmation))
        return card(stack)
    }

    private func toggleRow(title: String, detail: String, toggle: XDToggle) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = XDSpacing.md

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = XDSpacing.xxs

        let titleLabel = UILabel()
        titleLabel.text = title
        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.numberOfLines = 0
        bindTheme { traitCollection in
            titleLabel.font = XDFont.font(.bodyMedium, compatibleWith: traitCollection)
            titleLabel.textColor = XDColor.color(.textPrimary, compatibleWith: traitCollection)
            detailLabel.font = XDFont.font(.caption, compatibleWith: traitCollection)
            detailLabel.textColor = XDColor.color(.textSecondary, compatibleWith: traitCollection)
        }

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(detailLabel)
        row.addArrangedSubview(textStack)
        row.addArrangedSubview(toggle)
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            toggle.widthAnchor.constraint(equalToConstant: 52)
        ])
        return row
    }

    private func bottomSheetSamples() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = XDSpacing.sm
        let openDemo = XDButton(style: .primary, size: .large)
        openDemo.setTitle("打开 XDBottomSheet 独立体验页", for: .normal)
        openDemo.setIcon(.arrowForward, placement: .trailing)
        openDemo.onTap = { [weak self] in
            self?.navigationController?.pushViewController(XDBottomSheetDemoViewController(), animated: true)
        }
        stack.addArrangedSubview(openDemo)
        return card(stack)
    }

    private func buttonGroupTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        bindTheme { traitCollection in
            label.font = XDFont.font(.caption, compatibleWith: traitCollection)
            label.textColor = XDColor.color(.textSecondary, compatibleWith: traitCollection)
        }
        return label
    }

    private func card(_ content: UIView) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = XDRadius.md
        container.layer.borderWidth = XDBorder.regular
        bindTheme { traitCollection in
            container.backgroundColor = XDColor.color(.backgroundPrimary, compatibleWith: traitCollection)
            container.layer.borderColor = XDColor.color(.borderPrimary, compatibleWith: traitCollection).cgColor
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

    @objc private func handleThemeControlChanged() {
        let theme: XDTheme = themeControl.selectedSegmentIndex == 1 ? .blueTheme : .defaultTheme
        do {
            try XDThemeManager.shared.apply(theme)
        } catch {
            assertionFailure("Built-in theme is invalid: \(error)")
        }
    }
}
