import XCTest
@testable import XDDesignKit

@MainActor
final class XDBottomSheetTests: XCTestCase {
    func testConfigurationDefaultsToAnimatingContentSizeChanges() {
        XCTAssertTrue(XDBottomSheetConfiguration().animatesContentSizeChanges)
        XCTAssertFalse(
            XDBottomSheetConfiguration(animatesContentSizeChanges: false).animatesContentSizeChanges
        )
    }

    func testContentHeightIsEstablishedBeforeFirstLayoutAndCanBeInvalidated() {
        let contentController = UIViewController()
        let content = UIView()
        contentController.view.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        let contentHeight = content.heightAnchor.constraint(equalToConstant: 128)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: contentController.view.topAnchor),
            content.leadingAnchor.constraint(equalTo: contentController.view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: contentController.view.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: contentController.view.bottomAnchor),
            contentHeight
        ])

        let controller = makeController(content: contentController)
        controller.loadViewIfNeeded()
        guard let surfaceView = contentController.view.superview else {
            return XCTFail("Expected the content controller to be installed in a surface")
        }

        XCTAssertFalse(
            surfaceView.constraints.contains {
                $0.isActive
                    && $0.firstItem === surfaceView
                    && $0.firstAttribute == .height
            }
        )

        layout(controller, size: CGSize(width: 390, height: 844))
        XCTAssertEqual(surfaceView.bounds.height, 128, accuracy: 0.5)

        contentHeight.constant = 196
        controller.invalidateLayout(animated: false)
        XCTAssertEqual(surfaceView.bounds.height, 196, accuracy: 0.5)
    }

    func testFixedFractionAndWidthStrategiesResolveAgainstCurrentContainer() {
        let fixedContent = UIViewController()
        let fixedController = makeController(
            content: fixedContent,
            configuration: .init(height: .fixed(240), width: .horizontalInsets(20))
        )
        layout(fixedController, size: CGSize(width: 400, height: 800))
        XCTAssertEqual(fixedContent.view.superview?.bounds.width ?? 0, 360, accuracy: 0.5)
        XCTAssertEqual(fixedContent.view.superview?.bounds.height ?? 0, 240, accuracy: 0.5)

        let fractionContent = UIViewController()
        let fractionController = makeController(
            content: fractionContent,
            configuration: .init(height: .fraction(0.5), width: .centered(maximumWidth: 280))
        )
        layout(fractionController, size: CGSize(width: 400, height: 800))
        XCTAssertEqual(fractionContent.view.superview?.bounds.width ?? 0, 280, accuracy: 0.5)
        XCTAssertEqual(fractionContent.view.superview?.bounds.height ?? 0, 400, accuracy: 0.5)
    }

    func testFullWidthUsesWindowBoundsAfterLandscapeSizeChange() {
        let content = UIViewController()
        let controller = makeController(
            content: content,
            configuration: .init(height: .fixed(200), width: .fullWidth)
        )

        layout(controller, size: CGSize(width: 390, height: 844))
        XCTAssertEqual(content.view.superview?.bounds.width ?? 0, 390, accuracy: 0.5)

        layout(controller, size: CGSize(width: 844, height: 390))
        XCTAssertEqual(content.view.superview?.bounds.width ?? 0, 844, accuracy: 0.5)
    }

    func testFullWidthIgnoresHorizontalSafeAreaWhileInsetStrategiesRespectIt() {
        let landscapeInsets = UIEdgeInsets(top: 0, left: 59, bottom: 21, right: 59)

        XCTAssertEqual(
            XDBottomSheetWidthResolver.resolve(
                .fullWidth,
                windowWidth: 844,
                safeAreaInsets: landscapeInsets
            ),
            844,
            accuracy: 0.001
        )
        XCTAssertEqual(
            XDBottomSheetWidthResolver.resolve(
                .horizontalInsets(20),
                windowWidth: 844,
                safeAreaInsets: landscapeInsets
            ),
            686,
            accuracy: 0.001
        )
        XCTAssertEqual(
            XDBottomSheetWidthResolver.resolve(
                .centered(maximumWidth: 700),
                windowWidth: 844,
                safeAreaInsets: landscapeInsets
            ),
            700,
            accuracy: 0.001
        )
    }

    func testScrollResolverFindsOneVisibleVerticalScrollView() {
        let rootView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 500))
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        scrollView.contentSize = CGSize(width: 320, height: 600)
        rootView.addSubview(scrollView)

        guard case .single(let resolved) = XDBottomSheetScrollResolver.resolve(in: rootView) else {
            return XCTFail("Expected one vertical scroll view")
        }
        XCTAssertTrue(resolved === scrollView)

        scrollView.contentInset.top = 12
        scrollView.contentOffset.y = -12
        XCTAssertTrue(XDBottomSheetScrollResolver.isAtTop(scrollView))
        scrollView.contentOffset.y = 40
        XCTAssertFalse(XDBottomSheetScrollResolver.isAtTop(scrollView))
    }

    func testScrollResolverRequiresExplicitChoiceForMultipleCandidates() {
        let rootView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 500))
        for originY in [CGFloat(0), 250] {
            let scrollView = UIScrollView(frame: CGRect(x: 0, y: originY, width: 320, height: 200))
            scrollView.contentSize = CGSize(width: 320, height: 500)
            rootView.addSubview(scrollView)
        }

        guard case .ambiguous = XDBottomSheetScrollResolver.resolve(in: rootView) else {
            return XCTFail("Expected multiple scroll views to remain ambiguous")
        }

        rootView.subviews[1].isHidden = true
        guard case .single(let resolved) = XDBottomSheetScrollResolver.resolve(in: rootView) else {
            return XCTFail("Expected hidden candidates to be ignored")
        }
        XCTAssertTrue(resolved === rootView.subviews[0])
    }

    func testKeyboardGeometryOnlyMovesForBottomDockedKeyboard() {
        let bounds = CGRect(x: 0, y: 0, width: 1_024, height: 768)

        XCTAssertEqual(
            XDBottomSheetKeyboardGeometry.dockedOverlap(
                in: bounds,
                keyboardFrame: CGRect(x: 0, y: 468, width: 1_024, height: 300)
            ),
            300,
            accuracy: 0.001
        )
        XCTAssertEqual(
            XDBottomSheetKeyboardGeometry.dockedOverlap(
                in: bounds,
                keyboardFrame: CGRect(x: 600, y: 300, width: 360, height: 260)
            ),
            0,
            accuracy: 0.001
        )
    }

    func testSystemDismissalEmitsWillThenDidOnlyOnce() {
        var callbacks: [String] = []
        let controller = makeController(
            content: UIViewController(),
            events: .init(
                onWillDismiss: { callbacks.append("will:\($0.rawValue)") },
                onDidDismiss: { callbacks.append("did:\($0.rawValue)") }
            )
        )
        controller.loadViewIfNeeded()

        controller.beginAppearanceTransition(false, animated: false)
        controller.endAppearanceTransition()
        controller.beginAppearanceTransition(false, animated: false)
        controller.endAppearanceTransition()

        XCTAssertEqual(callbacks, ["will:system", "did:system"])
    }

    private func makeController(
        content: UIViewController,
        configuration: XDBottomSheetConfiguration = .init(),
        events: XDBottomSheetEvents = .init()
    ) -> XDBottomSheetViewController {
        XDBottomSheetViewController(
            contentViewController: content,
            configuration: configuration,
            events: events,
            themeContext: XDThemeManager.shared.globalContext
        )
    }

    private func layout(_ controller: XDBottomSheetViewController, size: CGSize) {
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
    }
}
