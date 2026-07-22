import XCTest
@testable import XDDesignKit

@MainActor
final class XDDesignKitTests: XCTestCase {
    func testVersionIsNotEmpty() {
        XCTAssertFalse(XDDesignKit.version.isEmpty)
    }

    func testHexColorInitializer() {
        let color = UIColor(hex: 0xFF542A)
        XCTAssertEqual(color.hexString, "#FF542A")
    }

    func testDefaultThemeIsComplete() {
        XCTAssertTrue(XDTheme.defaultTheme.validationResult().isValid)
        XCTAssertTrue(XDTheme.blueTheme.validationResult().isValid)
    }

    func testThemeResolvesLightDarkAndBrandVariants() throws {
        let light = UITraitCollection(userInterfaceStyle: .light)
        let dark = UITraitCollection(userInterfaceStyle: .dark)

        XCTAssertNotEqual(
            XDTheme.defaultTheme.color(for: .backgroundPrimary, compatibleWith: light).hexString,
            XDTheme.defaultTheme.color(for: .backgroundPrimary, compatibleWith: dark).hexString
        )
        XCTAssertEqual(
            XDTheme.blueTheme.color(for: .brandPrimary, compatibleWith: light).hexString,
            "#1677FF"
        )
        XCTAssertEqual(
            XDTheme.blueTheme.color(for: .brandPrimarySubtle, compatibleWith: light).hexString,
            "#EAF3FF"
        )
    }

    func testThemeColorSupportsAccessibilityContrast() {
        let color = XDThemeColor(
            light: UIColor(hex: 0x111111),
            dark: UIColor(hex: 0xEEEEEE),
            lightHighContrast: UIColor(hex: 0x000000),
            darkHighContrast: UIColor(hex: 0xFFFFFF)
        )
        let lightHighContrast = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: .light),
            UITraitCollection(accessibilityContrast: .high)
        ])
        let darkHighContrast = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: .dark),
            UITraitCollection(accessibilityContrast: .high)
        ])
        XCTAssertEqual(color.resolved(compatibleWith: lightHighContrast).hexString, "#000000")
        XCTAssertEqual(color.resolved(compatibleWith: darkHighContrast).hexString, "#FFFFFF")
    }

    func testComponentStateCanCombineValues() {
        var state: XDComponentState = .normal
        XCTAssertTrue(state.isNormal)
        state.formUnion([.highlighted, .selected])
        XCTAssertTrue(state.contains(.highlighted))
        XCTAssertTrue(state.contains(.selected))
        XCTAssertFalse(state.contains(.disabled))
    }

    func testThemeCanOverrideNonColorMetrics() throws {
        let metrics = XDThemeMetrics.default.merging(
            fonts: [.body: XDFontStyle(pointSize: 15, weight: .regular, textStyle: .body, lineHeight: 23)],
            spacings: [.md: 18],
            radii: [.md: 10],
            borderWidths: [.regular: 2]
        )
        let buttonTheme = XDButtonTheme.default.merging(metrics: [
            .large: XDButtonMetric(height: 52, horizontalPadding: 24, fontToken: .body, radiusToken: .md)
        ])
        let theme = XDTheme(
            identifier: "xd.metric-test",
            displayName: "Metric Test",
            colors: [:],
            metrics: metrics,
            components: XDThemeComponents.default.merging(button: buttonTheme),
            basedOn: .defaultTheme
        )
        let context = try XDThemeContext(initialTheme: theme)

        XCTAssertEqual(context.currentTheme.metrics.fontStyle(for: .body).lineHeight, 23)
        XCTAssertEqual(XDSpacing.value(.md, theme: context.currentTheme), 18, accuracy: 0.001)
        XCTAssertEqual(XDRadius.value(.md, theme: context.currentTheme), 10, accuracy: 0.001)
        XCTAssertEqual(XDBorder.width(.regular, theme: context.currentTheme), 2, accuracy: 0.001)

        let button = XDButton(size: .large, themeContext: context)
        XCTAssertEqual(button.intrinsicContentSize.height, 52, accuracy: 0.001)
        XCTAssertEqual(button.contentEdgeInsets.left, 24, accuracy: 0.001)
    }

    func testAlertThemeCanBeOverriddenThroughThemeComponents() throws {
        let alert = XDAlertTheme.default.merging(
            cardMaximumWidth: 360,
            contentHorizontalInset: 28,
            sectionContentInset: 12,
            inputHeight: 52,
            closeButtonSize: 48,
            checkboxTitleSpacing: 6,
            checkboxMinimumHeight: 28,
            checkboxMinimumHitTargetSize: 48,
            presentationScale: 0.9
        )
        let theme = XDTheme(
            identifier: "xd.alert-metric-test",
            displayName: "Alert Metric Test",
            colors: [:],
            components: .default.merging(alert: alert),
            basedOn: .defaultTheme
        )
        let context = try XDThemeContext(initialTheme: theme)

        XCTAssertEqual(context.currentTheme.components.alert.cardMaximumWidth, 360, accuracy: 0.001)
        XCTAssertEqual(context.currentTheme.components.alert.contentHorizontalInset, 28, accuracy: 0.001)
        XCTAssertEqual(context.currentTheme.components.alert.sectionContentInset, 12, accuracy: 0.001)
        XCTAssertEqual(context.currentTheme.components.alert.inputHeight, 52, accuracy: 0.001)
        XCTAssertEqual(context.currentTheme.components.alert.closeButtonSize, 48, accuracy: 0.001)
        XCTAssertEqual(context.currentTheme.components.alert.checkboxTitleSpacing, 6, accuracy: 0.001)
        XCTAssertEqual(context.currentTheme.components.alert.checkboxMinimumHeight, 28, accuracy: 0.001)
        XCTAssertEqual(context.currentTheme.components.alert.checkboxMinimumHitTargetSize, 48, accuracy: 0.001)
        XCTAssertEqual(context.currentTheme.components.alert.presentationScale, 0.9, accuracy: 0.001)
    }

    func testAlertThemeRejectsTooSmallAccessibilityHitAreas() {
        let invalid = XDAlertTheme.default.merging(
            closeButtonSize: 40,
            checkboxMinimumHitTargetSize: 40
        )

        XCTAssertFalse(invalid.validationErrors().isEmpty)
    }

    func testAlertActionFactoriesKeepRoleAndAppearanceIndependent() {
        let cancel = XDAlertAction.cancel("取消")
        let primary = XDAlertAction.primary("确定")
        let destructive = XDAlertAction.destructive("删除")
        let text = XDAlertAction.text("稍后处理")

        XCTAssertEqual(cancel.role, .cancel)
        XCTAssertEqual(cancel.appearance, .outlined)
        XCTAssertEqual(primary.role, .normal)
        XCTAssertEqual(primary.appearance, .filled)
        XCTAssertEqual(destructive.role, .destructive)
        XCTAssertEqual(destructive.appearance, .filled)
        XCTAssertEqual(text.appearance, .text)
    }

    func testAlertActionSupportsManualDismissalForAsyncWork() {
        let action = XDAlertAction.primary("上传", automaticallyDismisses: false)

        XCTAssertFalse(action.automaticallyDismisses)
    }

    func testAlertReportsMissingSceneWithoutPresenting() {
        let presenter = UIViewController()
        let handle = XDAlert.show(
            on: presenter,
            title: "提示",
            actions: [.primary("知道了")]
        )

        XCTAssertEqual(handle.presentationFailure, .presenterNotAttachedToScene)
        XCTAssertFalse(handle.isPresented)
    }

    func testAlertTextAlignmentUsesVisualWidthInsteadOfFontLineHeight() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.minimumLineHeight = 24
                style.maximumLineHeight = 24
                return style
            }()
        ]

        XCTAssertEqual(
            XDAlertTextAlignmentResolver.alignment(
                for: NSAttributedString(string: "操作成功", attributes: attributes),
                availableWidth: 240
            ),
            .center
        )
        XCTAssertEqual(
            XDAlertTextAlignmentResolver.alignment(
                for: NSAttributedString(
                    string: "这是一段宽度明显超过弹窗内容区域的说明文字",
                    attributes: attributes
                ),
                availableWidth: 120
            ),
            .natural
        )
    }

    func testAlertTitleAndMessageUseAdaptiveAlignmentByDefault() throws {
        let context = try XDThemeContext(initialTheme: .defaultTheme)
        let contentView = XDAlertStandardContentView(
            configuration: .init(
                title: "提示",
                message: "这是一段宽度会超过弹窗单行内容区域的说明文字",
                showsCloseButton: true
            ),
            themeContext: context,
            onAction: { _ in },
            onClose: {}
        )
        layoutAlertContentView(contentView)

        let titleLabel = try XCTUnwrap(descendantLabels(in: contentView).first { $0.text == "提示" })
        let messageLabel = try XCTUnwrap(
            descendantLabels(in: contentView).first {
                $0.text == "这是一段宽度会超过弹窗单行内容区域的说明文字"
            }
        )

        XCTAssertEqual(titleLabel.textAlignment, .center)
        XCTAssertEqual(messageLabel.textAlignment, .natural)
    }

    func testAlertTitleAndMessageAlignmentCanBeOverriddenIndependently() throws {
        let context = try XDThemeContext(initialTheme: .defaultTheme)
        let contentView = XDAlertStandardContentView(
            configuration: .init(
                title: "提示",
                message: "这是一段宽度会超过弹窗单行内容区域的说明文字",
                showsCloseButton: true,
                titleAlignment: .leading,
                messageAlignment: .center
            ),
            themeContext: context,
            onAction: { _ in },
            onClose: {}
        )
        layoutAlertContentView(contentView)

        let titleLabel = try XCTUnwrap(descendantLabels(in: contentView).first { $0.text == "提示" })
        let messageLabel = try XCTUnwrap(
            descendantLabels(in: contentView).first {
                $0.text == "这是一段宽度会超过弹窗单行内容区域的说明文字"
            }
        )

        XCTAssertEqual(titleLabel.textAlignment, .natural)
        XCTAssertEqual(messageLabel.textAlignment, .center)
    }

    func testAlertTextLengthUsesComposedCharacters() {
        let field = UITextField()
        field.text = "背书📚学习"
        let controller = XDAlertTextFieldLengthController(maximumLength: 3)

        controller.enforceMaximumLength(in: field)

        XCTAssertEqual(field.text, "背书📚")
    }

    func testAlertStandardConfigurationAcceptsSupportedAccessories() {
        let checkbox = XDAlertConfiguration(
            title: "删除分类",
            message: "此操作无法撤销",
            accessory: .checkbox(title: "同时删除文档", isSelected: true),
            actions: [.cancel("取消"), .primary("删除")]
        )
        let textField = XDAlertConfiguration(
            title: "新建分类",
            accessory: .textField(placeholder: "请输入名称", maximumLength: 20),
            actions: [.primary("确定")]
        )

        XCTAssertEqual(checkbox.actions.count, 2)
        XCTAssertEqual(textField.actions.count, 1)
    }

    func testAlertCheckboxAssetsAreBundled() {
        XCTAssertNotNil(
            UIImage(
                named: "xd_alert_checkbox_unselected",
                in: XDBundle.module,
                compatibleWith: nil
            )
        )
        XCTAssertNotNil(
            UIImage(
                named: "xd_alert_checkbox_selected",
                in: XDBundle.module,
                compatibleWith: nil
            )
        )
    }

    func testAlertCheckboxContentAndEmptyAreaHitTheControl() throws {
        let context = try XDThemeContext(initialTheme: .defaultTheme)
        let contentView = XDAlertStandardContentView(
            configuration: .init(
                title: "提示",
                accessory: .checkbox(title: "同时删除分类下的文档"),
                showsCloseButton: true
            ),
            themeContext: context,
            onAction: { _ in },
            onClose: {}
        )
        let fittedSize = contentView.systemLayoutSizeFitting(
            CGSize(width: 272, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        contentView.frame = CGRect(origin: .zero, size: fittedSize)
        contentView.layoutIfNeeded()

        let checkbox = descendantControls(in: contentView).first {
            $0.accessibilityLabel == "同时删除分类下的文档"
        }
        let control = try XCTUnwrap(checkbox)

        XCTAssertEqual(control.bounds.height, 24, accuracy: 0.001)
        XCTAssertTrue(control.point(inside: CGPoint(x: control.bounds.midX, y: -9), with: nil))
        XCTAssertTrue(control.point(inside: CGPoint(x: control.bounds.midX, y: control.bounds.maxY + 9), with: nil))
        XCTAssertTrue(control.hitTest(CGPoint(x: 12, y: control.bounds.midY), with: nil) === control)
        XCTAssertTrue(
            control.hitTest(
                CGPoint(x: control.bounds.maxX - 1, y: control.bounds.midY),
                with: nil
            ) === control
        )
    }

    func testAlertCheckboxVariantMatchesFigmaLayoutMetrics() throws {
        let context = try XDThemeContext(initialTheme: .defaultTheme)
        let contentView = XDAlertStandardContentView(
            configuration: .init(
                title: "确定删除分类吗？",
                message: "删除分类后，该分类下的背书文档将变成无分类",
                accessory: .checkbox(title: "同时删除分类下的背书文档"),
                actions: [.cancel("button"), .primary("button")]
            ),
            themeContext: context,
            onAction: { _ in },
            onClose: {}
        )
        let contentWidth = XDAlertTheme.default.cardMaximumWidth
            - 2 * XDAlertTheme.default.contentHorizontalInset
        let fittedSize = contentView.systemLayoutSizeFitting(
            CGSize(width: contentWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        XCTAssertEqual(contentWidth, 272, accuracy: 0.001)
        XCTAssertEqual(fittedSize.height, 222, accuracy: 0.001)
        XCTAssertEqual(
            fittedSize.height + 2 * XDAlertTheme.default.contentVerticalInset,
            250,
            accuracy: 0.001
        )
    }

    private func descendantControls(in view: UIView) -> [UIControl] {
        view.subviews.flatMap { subview in
            (subview as? UIControl).map { [$0] } ?? descendantControls(in: subview)
        }
    }

    private func descendantLabels(in view: UIView) -> [UILabel] {
        view.subviews.flatMap { subview in
            (subview as? UILabel).map { [$0] } ?? descendantLabels(in: subview)
        }
    }

    private func layoutAlertContentView(_ contentView: XDAlertStandardContentView) {
        let contentWidth = XDAlertTheme.default.cardMaximumWidth
            - 2 * XDAlertTheme.default.contentHorizontalInset
        let fittedSize = contentView.systemLayoutSizeFitting(
            CGSize(width: contentWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        contentView.frame = CGRect(origin: .zero, size: fittedSize)
        contentView.layoutIfNeeded()
    }

    func testPingFangFontFamilyResolvesProjectWeightsAndFallsBackSafely() {
        XCTAssertEqual(XDFontFamily.pingFangSC.font(ofSize: 16, weight: .regular).fontName, "PingFangSC-Regular")
        XCTAssertEqual(XDFontFamily.pingFangSC.font(ofSize: 18, weight: .medium).fontName, "PingFangSC-Medium")
        XCTAssertEqual(XDFontFamily.pingFangSC.font(ofSize: 20, weight: .semibold).fontName, "PingFangSC-Semibold")

        let unavailable = XDFontFamily(
            regularName: "Missing-Regular",
            mediumName: "Missing-Medium",
            semiboldName: "Missing-Semibold"
        )
        XCTAssertEqual(
            unavailable.font(ofSize: 16, weight: .regular).fontName,
            UIFont.systemFont(ofSize: 16, weight: .regular).fontName
        )
    }

    func testFixedFontFactoryUsesThemeFamilyAndKeepsRequestedSize() {
        let regular = XDFont.fixed.regular(16, theme: .defaultTheme)
        let medium = XDFont.fixed.medium(18, theme: .defaultTheme)
        let semibold = XDFont.fixed.semibold(20, theme: .defaultTheme)

        XCTAssertEqual(regular.fontName, "PingFangSC-Regular")
        XCTAssertEqual(regular.pointSize, 16, accuracy: 0.001)
        XCTAssertEqual(medium.fontName, "PingFangSC-Medium")
        XCTAssertEqual(medium.pointSize, 18, accuracy: 0.001)
        XCTAssertEqual(semibold.fontName, "PingFangSC-Semibold")
        XCTAssertEqual(semibold.pointSize, 20, accuracy: 0.001)
    }

    func testFontScalingPolicyDistinguishesFixedAndDynamicTypography() {
        let standardTraits = UITraitCollection(preferredContentSizeCategory: .large)
        let accessibilityTraits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        let fixed = XDFontStyle(
            pointSize: 16,
            weight: .regular,
            textStyle: .body,
            scaling: .fixed
        )
        let dynamic = XDFontStyle(
            pointSize: 16,
            weight: .regular,
            textStyle: .body,
            scaling: .dynamic
        )

        XCTAssertEqual(
            fixed.resolved(compatibleWith: accessibilityTraits).pointSize,
            fixed.resolved(compatibleWith: standardTraits).pointSize,
            accuracy: 0.001
        )
        XCTAssertGreaterThan(
            dynamic.resolved(compatibleWith: accessibilityTraits).pointSize,
            dynamic.resolved(compatibleWith: standardTraits).pointSize
        )
    }

    func testCustomFontTokenResolvesAndUnknownTokenFallsBackWithoutRecursion() {
        let custom = XDFontToken(rawValue: "application.navigation.title")
        let unknown = XDFontToken(rawValue: "application.missing")
        let metrics = XDThemeMetrics.default.merging(fonts: [
            custom: XDFontStyle(
                pointSize: 18,
                weight: .semibold,
                textStyle: .headline,
                lineHeight: 26,
                scaling: .fixed
            )
        ])

        XCTAssertEqual(metrics.fontStyleIfDefined(for: custom)?.pointSize, 18)
        XCTAssertNil(metrics.fontStyleIfDefined(for: unknown))
        XCTAssertEqual(metrics.fontStyle(for: unknown).pointSize, metrics.fontStyle(for: .body).pointSize)
        XCTAssertEqual(metrics.fontStyle(for: unknown).weight, metrics.fontStyle(for: .body).weight)
    }

    func testThemeInheritanceIsExplicitAndIncompleteRootIsRejected() {
        let incompleteRoot = XDTheme(
            identifier: "xd.incomplete",
            displayName: "Incomplete",
            colors: [:],
            metrics: .default,
            components: .default,
            basedOn: nil
        )

        XCTAssertFalse(incompleteRoot.validationResult().isValid)
        XCTAssertThrowsError(try XDThemeContext(initialTheme: incompleteRoot))
    }

    func testThemeValidationRejectsNonFiniteValuesAndEmptyIdentity() {
        let invalidMetrics = XDThemeMetrics.default.merging(opacities: [.overlay: .nan])
        let invalidTheme = XDTheme(
            identifier: " ",
            displayName: "Invalid",
            colors: [:],
            metrics: invalidMetrics,
            basedOn: .defaultTheme
        )
        let errors = invalidTheme.validationResult().errors
        XCTAssertTrue(errors.contains(where: { $0.contains("identifier") }))
        XCTAssertTrue(errors.contains(where: { $0.contains("Opacity") }))
    }

    func testThemeValidationRejectsInvalidTypographyConfiguration() {
        let invalidMetrics = XDThemeMetrics.default.merging(
            fontFamily: XDFontFamily(
                regularName: " ",
                mediumName: "PingFangSC-Medium",
                semiboldName: "PingFangSC-Semibold"
            ),
            fonts: [
                .body: XDFontStyle(
                    pointSize: 16,
                    weight: .regular,
                    textStyle: .body,
                    maximumPointSize: 20,
                    scaling: .fixed
                )
            ]
        )
        let invalidTheme = XDTheme(
            identifier: "xd.invalid-typography",
            displayName: "Invalid Typography",
            colors: [:],
            metrics: invalidMetrics,
            basedOn: .defaultTheme
        )

        let errors = invalidTheme.validationResult().errors
        XCTAssertTrue(errors.contains(where: { $0.contains("Font family") }))
        XCTAssertTrue(errors.contains(where: { $0.contains("Fixed fonts") }))
    }

    func testCustomTokensCanBeAddedWithoutChangingLibraryTypes() {
        let custom = XDColorToken(rawValue: "application.promotion.background")
        let theme = XDTheme(
            identifier: "xd.custom-token",
            displayName: "Custom Token",
            colors: [custom: XDThemeColor(UIColor(hex: 0x123456))],
            basedOn: .defaultTheme
        )
        let traits = UITraitCollection(userInterfaceStyle: .light)
        XCTAssertEqual(theme.color(for: custom, compatibleWith: traits).hexString, "#123456")
    }

    func testThemeContextsAreIsolated() throws {
        let firstContext = try XDThemeContext(initialTheme: .defaultTheme)
        let secondContext = try XDThemeContext(initialTheme: .blueTheme)
        let traits = UITraitCollection(userInterfaceStyle: .light)

        XCTAssertNotEqual(
            firstContext.color(for: .brandPrimary, compatibleWith: traits).hexString,
            secondContext.color(for: .brandPrimary, compatibleWith: traits).hexString
        )
        try secondContext.apply(.defaultTheme)
        XCTAssertEqual(firstContext.currentTheme.identifier, XDTheme.defaultTheme.identifier)
        XCTAssertEqual(secondContext.currentTheme.identifier, XDTheme.defaultTheme.identifier)
    }

    func testThemeableObservesOnlyItsInjectedContext() throws {
        let context = try XDThemeContext(initialTheme: .defaultTheme)
        let otherContext = try XDThemeContext(initialTheme: .defaultTheme)
        let probe = ThemeProbe(context: context)

        probe.xdRegisterThemeUpdates()
        try otherContext.apply(.blueTheme)
        XCTAssertEqual(probe.applyCount, 0)
        try context.apply(.blueTheme)
        XCTAssertEqual(probe.applyCount, 1)
    }

    func testContextResolverKeepsLayerShadowLocal() throws {
        let customMetrics = XDThemeMetrics.default.merging(shadows: [
            .card: XDShadowStyle(colorToken: .brandPrimary, offset: CGSize(width: 1, height: 3), radius: 5, opacity: 0.2)
        ])
        let theme = XDTheme(
            identifier: "xd.shadow",
            displayName: "Shadow",
            colors: [.brandPrimary: XDThemeColor(UIColor(hex: 0x123456))],
            metrics: customMetrics,
            basedOn: .defaultTheme
        )
        let context = try XDThemeContext(initialTheme: theme)
        let resolver = context.resolver(compatibleWith: UITraitCollection(userInterfaceStyle: .light))
        let layer = CALayer()
        layer.xdApplyShadow(.card, resolver: resolver)

        XCTAssertEqual(layer.shadowOffset, CGSize(width: 1, height: 3))
        XCTAssertEqual(layer.shadowRadius, 5, accuracy: 0.001)
        XCTAssertEqual(layer.shadowOpacity, 0.2, accuracy: 0.001)
        XCTAssertEqual(UIColor(cgColor: layer.shadowColor!).hexString, "#123456")
    }

    func testButtonDisabledStylesDoNotGainUnexpectedBorders() throws {
        let context = try XDThemeContext(initialTheme: .defaultTheme)
        for style in [XDButtonStyle.primary, .text] {
            let button = XDButton(style: style, themeContext: context)
            button.isEnabled = false
            XCTAssertEqual(button.layer.borderWidth, 0, "Unexpected disabled border for \(style.rawValue)")
        }
    }

    func testButtonIntrinsicWidthCountsPaddingOnce() throws {
        let compactTheme = XDTheme(
            identifier: "xd.compact-button",
            displayName: "Compact Button",
            colors: [:],
            components: .default.merging(button: .default.merging(metrics: [
                .large: XDButtonMetric(height: 48, horizontalPadding: 10, fontToken: .bodyMedium, radiusToken: .md)
            ])),
            basedOn: .defaultTheme
        )
        let roomyTheme = XDTheme(
            identifier: "xd.roomy-button",
            displayName: "Roomy Button",
            colors: [:],
            components: .default.merging(button: .default.merging(metrics: [
                .large: XDButtonMetric(height: 48, horizontalPadding: 30, fontToken: .bodyMedium, radiusToken: .md)
            ])),
            basedOn: .defaultTheme
        )
        let compact = XDButton(themeContext: try XDThemeContext(initialTheme: compactTheme))
        let roomy = XDButton(themeContext: try XDThemeContext(initialTheme: roomyTheme))
        compact.setTitle("Button", for: .normal)
        roomy.setTitle("Button", for: .normal)

        XCTAssertEqual(roomy.intrinsicContentSize.width - compact.intrinsicContentSize.width, 40, accuracy: 0.5)
    }

    func testButtonUnknownCustomSizeFallsBackToLargeMetric() {
        let custom = XDButton(size: XDButtonSize(rawValue: "application.missing-size"))
        let large = XDButton(size: .large)
        custom.setTitle("Button", for: .normal)
        large.setTitle("Button", for: .normal)

        XCTAssertEqual(custom.intrinsicContentSize.width, large.intrinsicContentSize.width, accuracy: 0.5)
        XCTAssertEqual(custom.intrinsicContentSize.height, large.intrinsicContentSize.height, accuracy: 0.5)
    }

    func testButtonSelectedAppearanceAndMinimumHitTarget() throws {
        let context = try XDThemeContext(initialTheme: .defaultTheme)
        let button = XDButton(style: .primary, size: .small, themeContext: context)
        button.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        button.isSelected = true

        XCTAssertEqual(button.backgroundColor?.hexString, "#333333")
        XCTAssertTrue(button.point(inside: CGPoint(x: 16, y: -5), with: nil))
    }

    func testButtonDisabledAppearanceWinsCombinedState() throws {
        let context = try XDThemeContext(initialTheme: .defaultTheme)
        let button = XDButton(style: .primary, themeContext: context)
        button.isSelected = true
        button.isHighlighted = true
        button.isEnabled = false
        XCTAssertEqual(button.backgroundColor?.hexString, "#F2F2F2")
    }

    func testButtonPrimaryAndOutlineMatchProjectSpecification() throws {
        let context = try XDThemeContext(initialTheme: .defaultTheme)
        let primary = XDButton(style: .primary, size: .large, themeContext: context)
        let outline = XDButton(style: .outline, size: .large, themeContext: context)
        primary.setTitle("button", for: .normal)
        outline.setTitle("button", for: .normal)

        XCTAssertEqual(primary.backgroundColor?.hexString, "#222222")
        XCTAssertEqual(primary.currentTitleColor.hexString, "#FFFFFF")
        XCTAssertEqual(primary.intrinsicContentSize.height, 48, accuracy: 0.5)
        XCTAssertEqual(primary.layer.cornerRadius, 8, accuracy: 0.001)
        XCTAssertEqual(primary.titleLabel!.font.pointSize, 16, accuracy: 0.001)
        XCTAssertEqual(primary.titleLabel!.font.fontName, "PingFangSC-Regular")
        XCTAssertEqual(primary.layer.borderWidth, 0, accuracy: 0.001)

        XCTAssertEqual(outline.backgroundColor?.hexString, "#FFFFFF")
        XCTAssertEqual(outline.currentTitleColor.hexString, "#222222")
        XCTAssertEqual(UIColor(cgColor: outline.layer.borderColor!).hexString, "#222222")
        XCTAssertEqual(outline.layer.borderWidth, 0.5, accuracy: 0.001)
        XCTAssertEqual(outline.intrinsicContentSize.height, 48, accuracy: 0.5)
        XCTAssertEqual(outline.layer.cornerRadius, 8, accuracy: 0.001)
        XCTAssertEqual(outline.titleLabel!.font.pointSize, 16, accuracy: 0.001)
        XCTAssertEqual(outline.titleLabel!.font.fontName, "PingFangSC-Regular")
    }

    func testButtonPrimaryAndOutlineColorsStayFixedInDarkMode() {
        let buttonTheme = XDTheme.defaultTheme.components.button
        let lightResolver = XDThemeResolver(
            theme: .defaultTheme,
            traitCollection: UITraitCollection(userInterfaceStyle: .light)
        )
        let darkResolver = XDThemeResolver(
            theme: .defaultTheme,
            traitCollection: UITraitCollection(userInterfaceStyle: .dark)
        )

        for style in [XDButtonStyle.primary, .outline] {
            let appearance = buttonTheme.appearance(for: style, state: .normal)
            XCTAssertEqual(
                buttonTheme.color(for: appearance.titleToken, resolver: lightResolver).hexString,
                buttonTheme.color(for: appearance.titleToken, resolver: darkResolver).hexString
            )
            XCTAssertEqual(
                buttonTheme.color(for: appearance.backgroundToken!, resolver: lightResolver).hexString,
                buttonTheme.color(for: appearance.backgroundToken!, resolver: darkResolver).hexString
            )
        }
    }

    func testButtonCanRebindDecodedContextWithoutObservingOldContext() throws {
        let oldContext = try XDThemeContext(initialTheme: .defaultTheme)
        let newContext = try XDThemeContext(initialTheme: .blueTheme)
        let button = XDButton(style: .brand, themeContext: oldContext)
        button.bindThemeContext(newContext)

        let traits = button.traitCollection
        XCTAssertEqual(button.backgroundColor?.hexString, "#1677FF")

        let redTheme = XDTheme(
            identifier: "xd.red",
            displayName: "Red",
            colors: [.brandPrimary: XDThemeColor(UIColor(hex: 0xCC0000))],
            basedOn: .defaultTheme
        )
        try oldContext.apply(redTheme)
        XCTAssertEqual(button.backgroundColor?.hexString, "#1677FF")

        try newContext.apply(.defaultTheme)
        XCTAssertEqual(
            button.backgroundColor?.hexString,
            newContext.color(for: .brandPrimary, compatibleWith: traits).hexString
        )
    }

    func testButtonSemanticIconUsesConfiguredMetric() throws {
        let metric = XDButtonMetric(
            height: 48,
            horizontalPadding: 20,
            iconSize: 28,
            contentSpacing: 11,
            fontToken: .bodyMedium,
            radiusToken: .md
        )
        let theme = XDTheme(
            identifier: "xd.button-icon-metric",
            displayName: "Button Icon Metric",
            colors: [:],
            components: .default.merging(button: .default.merging(metrics: [.large: metric])),
            basedOn: .defaultTheme
        )
        let context = try XDThemeContext(initialTheme: theme)
        let titleOnly = XDButton(themeContext: context)
        let withIcon = XDButton(themeContext: context)
        titleOnly.setTitle("Continue", for: .normal)
        withIcon.setTitle("Continue", for: .normal)
        withIcon.setIcon(.arrowForward, placement: .trailing)

        XCTAssertNotNil(withIcon.currentImage)
        XCTAssertEqual(
            withIcon.intrinsicContentSize.width - titleOnly.intrinsicContentSize.width,
            39,
            accuracy: 0.5
        )
    }

    func testButtonNativeImageTakesOwnershipFromSemanticIcon() {
        let button = XDButton()
        let nativeImage = UIImage(systemName: "star")!
        button.setIcon(.arrowForward)

        button.setImage(nativeImage, for: .normal)
        button.xdApplyTheme()
        XCTAssertTrue(button.image(for: .normal) === nativeImage)

        button.setImage(nil, for: .normal)
        button.xdApplyTheme()
        XCTAssertNil(button.image(for: .normal))
    }

    func testButtonCustomIconProviderAndDirectionalMetadataAreApplied() {
        let provider = IconProviderProbe()
        let button = XDButton(iconProvider: provider)
        let token = XDIconToken(rawValue: "application.next")

        button.setIcon(token)

        XCTAssertEqual(provider.requestedTokens, [token])
        XCTAssertNotNil(button.currentImage)
        XCTAssertEqual(button.currentImage?.flipsForRightToLeftLayoutDirection, true)
    }

    func testButtonFontMetricRespondsToAccessibilityContentSize() {
        let theme = XDTheme.defaultTheme
        let metric = XDButtonSize.large.metric(in: theme)
        let standard = XDThemeResolver(
            theme: theme,
            traitCollection: UITraitCollection(preferredContentSizeCategory: .large)
        ).font(metric.fontToken)
        let accessible = XDThemeResolver(
            theme: theme,
            traitCollection: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        ).font(metric.fontToken)

        XCTAssertGreaterThan(accessible.pointSize, standard.pointSize)
        XCTAssertGreaterThan(accessible.lineHeight, standard.lineHeight)
    }

    func testButtonLeadingIconMirrorsLayoutInRightToLeft() {
        let button = XDButton(style: .primary, size: .large)
        button.setTitle("Continue", for: .normal)
        button.setIcon(.arrowForward, placement: .leading)
        button.frame = CGRect(origin: .zero, size: CGSize(width: 220, height: 48))

        button.semanticContentAttribute = .forceLeftToRight
        button.layoutIfNeeded()
        XCTAssertLessThan(button.imageView!.frame.minX, button.titleLabel!.frame.minX)

        button.semanticContentAttribute = .forceRightToLeft
        button.setNeedsLayout()
        button.layoutIfNeeded()
        XCTAssertGreaterThan(button.imageView!.frame.minX, button.titleLabel!.frame.minX)
    }

    func testButtonVerticalAndIconOnlyLayouts() {
        let top = XDButton(style: .text, size: .large)
        top.setTitle("Done", for: .normal)
        top.setIcon(.checkmarkCircle, placement: .top)
        top.frame = CGRect(origin: .zero, size: top.intrinsicContentSize)
        top.layoutIfNeeded()

        XCTAssertLessThanOrEqual(top.imageView!.frame.maxY, top.titleLabel!.frame.minY)

        let iconOnly = XDButton(style: .text, size: .small)
        iconOnly.setTitle("Refresh", for: .normal)
        iconOnly.setIcon(.refresh, placement: .only)
        XCTAssertEqual(iconOnly.intrinsicContentSize.width, 44, accuracy: 0.5)
        iconOnly.frame = CGRect(origin: .zero, size: iconOnly.intrinsicContentSize)
        iconOnly.layoutIfNeeded()
        XCTAssertEqual(iconOnly.titleLabel!.frame, .zero)
    }

    func testButtonCombinationLayoutsKeepContentGroupedCenteredAndSeparated() {
        let cases: [(XDButtonIconPlacement, Bool)] = [
            (.leading, false),
            (.trailing, false),
            (.top, true),
            (.bottom, true)
        ]

        for (placement, isVertical) in cases {
            let button = XDButton(style: .primary, size: .large)
            button.setTitle("点击体验", for: .normal)
            button.setIcon(.checkmarkCircle, placement: placement)
            button.frame = CGRect(origin: .zero, size: button.intrinsicContentSize)
            button.layoutIfNeeded()

            let title = try! XCTUnwrap(button.titleLabel)
            let image = try! XCTUnwrap(button.imageView)

            if isVertical {
                let first = placement == .top ? image.frame : title.frame
                let second = placement == .top ? title.frame : image.frame
                XCTAssertGreaterThanOrEqual(second.minY - first.maxY, 8, "\(placement.rawValue) spacing")
                XCTAssertEqual((min(title.frame.minY, image.frame.minY) + max(title.frame.maxY, image.frame.maxY)) / 2, button.bounds.midY, accuracy: 0.5, "\(placement.rawValue) group center")
            } else {
                let first = placement == .leading ? image.frame : title.frame
                let second = placement == .leading ? title.frame : image.frame
                XCTAssertGreaterThanOrEqual(second.minX - first.maxX, 8, "\(placement.rawValue) spacing")
                XCTAssertEqual(title.frame.midY, image.frame.midY, accuracy: 0.5, "\(placement.rawValue) vertical alignment")
                XCTAssertEqual((min(title.frame.minX, image.frame.minX) + max(title.frame.maxX, image.frame.maxX)) / 2, button.bounds.midX, accuracy: 0.5, "\(placement.rawValue) group center")
            }

            XCTAssertTrue(button.bounds.contains(title.frame), "\(placement.rawValue) title bounds")
            XCTAssertTrue(button.bounds.contains(image.frame), "\(placement.rawValue) icon bounds")
        }
    }

    func testButtonCombinationLayoutsStayCorrectInsideAnAutoLayoutStack() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 360, height: 400))
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        let button = XDButton(style: .primary, size: .large)
        button.setTitle("点击体验", for: .normal)
        stack.addArrangedSubview(button)

        let sequence: [(XDButtonIconPlacement, CGFloat?)] = [
            (.leading, nil),
            (.trailing, nil),
            (.top, 4),
            (.only, nil),
            (.bottom, 20),
            (.trailing, nil),
            (.top, nil),
            (.bottom, nil)
        ]

        for (index, item) in sequence.enumerated() {
            let placement = item.0
            button.semanticContentAttribute = index.isMultiple(of: 2) ? .forceLeftToRight : .forceRightToLeft
            button.stackedContentPaddingOverride = item.1
            button.setIcon(.checkmarkCircle, placement: placement)
            container.setNeedsLayout()
            container.layoutIfNeeded()

            let title = try! XCTUnwrap(button.titleLabel)
            let image = try! XCTUnwrap(button.imageView)
            XCTAssertTrue(button.bounds.contains(title.frame), "\(placement.rawValue) title bounds")
            XCTAssertTrue(button.bounds.contains(image.frame), "\(placement.rawValue) icon bounds")

            if placement == .only {
                XCTAssertEqual(title.frame, .zero, "icon-only title frame")
                XCTAssertEqual(image.frame.midX, button.bounds.midX, accuracy: 0.001, "icon-only horizontal center")
                XCTAssertEqual(image.frame.midY, button.bounds.midY, accuracy: 0.001, "icon-only vertical center")
            } else if placement == .leading || placement == .trailing {
                XCTAssertEqual(title.frame.midY, image.frame.midY, accuracy: 0.001, "\(placement.rawValue) vertical alignment")
            } else {
                let first = placement == .top ? image.frame : title.frame
                let second = placement == .top ? title.frame : image.frame
                XCTAssertEqual(title.frame.midX, image.frame.midX, accuracy: 0.001, "\(placement.rawValue) horizontal alignment")
                XCTAssertGreaterThanOrEqual(second.minY - first.maxY, 8, "\(placement.rawValue) spacing")
            }
        }
    }

    func testButtonStackedContentPaddingUsesThemeAndSupportsPerButtonOverride() {
        let button = XDButton(style: .text, size: .large)
        button.setTitle("Done", for: .normal)
        button.setIcon(.checkmarkCircle, placement: .top)

        XCTAssertEqual(button.contentEdgeInsets.top, 12, accuracy: 0.001)
        XCTAssertEqual(button.contentEdgeInsets.bottom, 12, accuracy: 0.001)
        let themeHeight = button.intrinsicContentSize.height

        button.stackedContentPaddingOverride = 20
        XCTAssertEqual(button.contentEdgeInsets.top, 20, accuracy: 0.001)
        XCTAssertEqual(button.contentEdgeInsets.bottom, 20, accuracy: 0.001)
        XCTAssertEqual(button.intrinsicContentSize.height - themeHeight, 16, accuracy: 0.5)

        button.iconPlacement = .leading
        XCTAssertEqual(button.contentEdgeInsets.top, 0, accuracy: 0.001)
        XCTAssertEqual(button.contentEdgeInsets.bottom, 0, accuracy: 0.001)
    }

    func testButtonLoadingBlocksActionsWithoutChangingEnabledState() {
        let button = XDButton()
        button.setTitle("Submit", for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 160, height: 48)
        let center = CGPoint(x: button.bounds.midX, y: button.bounds.midY)
        XCTAssertTrue(button.point(inside: center, with: nil))

        button.isLoading = true
        XCTAssertFalse(button.point(inside: center, with: nil))
        XCTAssertTrue(button.isEnabled)
        XCTAssertTrue(button.accessibilityTraits.contains(.updatesFrequently))

        button.isLoading = false
        XCTAssertTrue(button.point(inside: center, with: nil))

        button.isEnabled = false
        button.isLoading = true
        button.isLoading = false
        XCTAssertFalse(button.isEnabled)
    }

    func testButtonLoadingRestoresAccessibilityValue() {
        let button = XDButton()
        button.accessibilityValue = "Ready"
        button.loadingAccessibilityValue = "Loading"

        button.isLoading = true
        XCTAssertEqual(button.accessibilityValue, "Loading")
        button.isLoading = false
        XCTAssertEqual(button.accessibilityValue, "Ready")
    }

    func testButtonLoadingRestoresValueWhenLoadingLabelChangesAndPreservesExistingTrait() {
        let button = XDButton()
        button.accessibilityValue = "Ready"
        button.accessibilityTraits.insert(.updatesFrequently)
        button.loadingAccessibilityValue = "Loading"

        button.isLoading = true
        button.loadingAccessibilityValue = nil
        XCTAssertEqual(button.accessibilityValue, "Ready")

        button.isLoading = false
        XCTAssertEqual(button.accessibilityValue, "Ready")
        XCTAssertTrue(button.accessibilityTraits.contains(.updatesFrequently))
    }

    func testButtonGradientRendererDoesNotAccumulateLayers() {
        let button = XDButton(style: .gradient)
        button.setTitle("Upgrade", for: .normal)
        button.frame = CGRect(origin: .zero, size: CGSize(width: 240, height: 48))
        button.layoutIfNeeded()

        XCTAssertEqual(button.layer.sublayers?.filter { $0 is CAGradientLayer }.count, 1)
        button.isSelected = true
        button.layoutIfNeeded()
        XCTAssertEqual(button.layer.sublayers?.filter { $0 is CAGradientLayer }.count, 1)

        button.apply(style: .primary)
        button.layoutIfNeeded()
        XCTAssertEqual(button.layer.sublayers?.filter { $0 is CAGradientLayer }.count, 0)
    }

    func testButtonLayoutCalculatorPositionsSemanticLeadingIcon() {
        let base = XDButtonLayoutInput(
            bounds: CGRect(x: 0, y: 0, width: 200, height: 48),
            contentInsets: UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20),
            titleSize: CGSize(width: 60, height: 20),
            iconSize: CGSize(width: 20, height: 20),
            spacing: 8,
            placement: .leading,
            isRightToLeft: false,
            horizontalAlignment: .center,
            verticalAlignment: .center
        )
        let leftToRight = XDButtonLayout.calculate(base)
        XCTAssertLessThan(leftToRight.iconFrame.minX, leftToRight.titleFrame.minX)

        let rightToLeft = XDButtonLayout.calculate(
            XDButtonLayoutInput(
                bounds: base.bounds,
                contentInsets: base.contentInsets,
                titleSize: base.titleSize,
                iconSize: base.iconSize,
                spacing: base.spacing,
                placement: base.placement,
                isRightToLeft: true,
                horizontalAlignment: base.horizontalAlignment,
                verticalAlignment: base.verticalAlignment
            )
        )
        XCTAssertGreaterThan(rightToLeft.iconFrame.minX, rightToLeft.titleFrame.minX)
        XCTAssertEqual(leftToRight.contentSize, rightToLeft.contentSize)
    }

    func testButtonLayoutCalculatorSupportsFillAlignment() {
        let result = XDButtonLayout.calculate(
            XDButtonLayoutInput(
                bounds: CGRect(x: 0, y: 0, width: 200, height: 48),
                contentInsets: UIEdgeInsets(top: 4, left: 20, bottom: 4, right: 20),
                titleSize: CGSize(width: 60, height: 20),
                iconSize: CGSize(width: 20, height: 20),
                spacing: 8,
                placement: .leading,
                isRightToLeft: false,
                horizontalAlignment: .fill,
                verticalAlignment: .fill
            )
        )

        XCTAssertEqual(result.iconFrame.minX, 20, accuracy: 0.5)
        XCTAssertEqual(result.titleFrame.minX, 48, accuracy: 0.5)
        XCTAssertEqual(result.titleFrame.maxX, 180, accuracy: 0.5)
        XCTAssertEqual(result.titleFrame.height, 40, accuracy: 0.5)
    }

    func testButtonConstrainedLayoutKeepsContentInsideInsets() {
        let button = XDButton(style: .outline, size: .large)
        button.setTitle("A very long button title that must truncate", for: .normal)
        button.setIcon(.arrowForward, placement: .trailing)
        button.frame = CGRect(x: 0, y: 0, width: 180, height: 48)
        button.layoutIfNeeded()

        XCTAssertGreaterThanOrEqual(button.titleLabel!.frame.minX, button.contentEdgeInsets.left)
        XCTAssertLessThanOrEqual(
            button.imageView!.frame.maxX,
            button.bounds.maxX - button.contentEdgeInsets.right
        )
    }

    func testFoundationMetricsIncludeMotionTypographyAndPhysicalHairline() {
        let metrics = XDThemeMetrics.default
        let resolver = XDThemeResolver(
            theme: .defaultTheme,
            traitCollection: UITraitCollection(displayScale: 3)
        )
        XCTAssertEqual(metrics.motion(for: .standard).duration, 0.25, accuracy: 0.001)
        XCTAssertEqual(metrics.fontStyle(for: .body).lineHeight, 22)
        XCTAssertEqual(resolver.borderWidth(.hairline), 1.0 / 3.0, accuracy: 0.001)
        XCTAssertNotNil(resolver.textAttributes(font: .body, color: .textPrimary)[.paragraphStyle])
    }
}

@MainActor
private final class ThemeProbe: NSObject, XDThemeable {
    let xdThemeContext: XDThemeContext
    private(set) var applyCount = 0

    init(context: XDThemeContext) {
        self.xdThemeContext = context
    }

    func xdApplyTheme() { applyCount += 1 }
}

@MainActor
private final class IconProviderProbe: XDIconProviding {
    private(set) var requestedTokens: [XDIconToken] = []

    func icon(
        for token: XDIconToken,
        compatibleWith traitCollection: UITraitCollection
    ) -> XDResolvedIcon? {
        requestedTokens.append(token)
        guard let image = UIImage(systemName: "star") else { return nil }
        return XDResolvedIcon(image: image, mirrorsInRightToLeftLayout: true)
    }
}

private extension UIColor {
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(
            format: "#%02X%02X%02X",
            Int(round(red * 255)),
            Int(round(green * 255)),
            Int(round(blue * 255))
        )
    }
}
