import ObjectiveC
import UIKit

/// UIKit theme consumers are main-actor isolated by contract.
@MainActor
public protocol XDThemeable: AnyObject {
    var xdThemeContext: XDThemeContext { get }
    func xdApplyTheme()
}

public extension XDThemeable {
    var xdThemeContext: XDThemeContext { XDThemeManager.shared.globalContext }
}

@MainActor
private final class XDThemeObserver {
    weak var target: XDThemeable?
    private var notificationToken: XDNotificationToken?

    init(target: XDThemeable, context: XDThemeContext) {
        self.target = target
        let token = NotificationCenter.default.addObserver(
            forName: .xdThemeDidChange,
            object: context,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.target?.xdApplyTheme()
            }
        }
        notificationToken = XDNotificationToken(token)
    }

    func invalidate() {
        notificationToken = nil
    }
}

/// NotificationCenter's token protocol predates Sendable. This box owns the
/// token and performs the thread-safe removal when its owner is released.
private final class XDNotificationToken: @unchecked Sendable {
    private let token: NSObjectProtocol

    init(_ token: NSObjectProtocol) {
        self.token = token
    }

    deinit {
        NotificationCenter.default.removeObserver(token)
    }
}

@MainActor private var xdThemeObserverKey: UInt8 = 0

public extension XDThemeable where Self: NSObject {
    func xdRegisterThemeUpdates(applyImmediately: Bool = false) {
        if objc_getAssociatedObject(self, &xdThemeObserverKey) == nil {
            let observer = XDThemeObserver(target: self, context: xdThemeContext)
            objc_setAssociatedObject(self, &xdThemeObserverKey, observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        if applyImmediately { xdApplyTheme() }
    }

    func xdUnregisterThemeUpdates() {
        guard let observer = objc_getAssociatedObject(self, &xdThemeObserverKey) as? XDThemeObserver else { return }
        observer.invalidate()
        objc_setAssociatedObject(self, &xdThemeObserverKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

public extension XDThemeable where Self: UIView {
    var xdThemeResolver: XDThemeResolver {
        xdThemeContext.resolver(compatibleWith: traitCollection)
    }

    func xdThemeColor(_ token: XDColorToken) -> UIColor { xdThemeResolver.color(token) }
    func xdThemeFont(_ token: XDFontToken) -> UIFont { xdThemeResolver.font(token) }
    func xdThemeSpacing(_ token: XDSpacingToken) -> CGFloat { xdThemeResolver.spacing(token) }
    func xdThemeRadius(_ token: XDRadiusToken) -> CGFloat { xdThemeResolver.radius(token) }
    func xdThemeBorderWidth(_ token: XDBorderToken) -> CGFloat { xdThemeResolver.borderWidth(token) }

    func xdNeedsThemeUpdate(after previousTraitCollection: UITraitCollection?) -> Bool {
        guard let previousTraitCollection else { return true }
        return previousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection)
            || previousTraitCollection.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory
            || previousTraitCollection.layoutDirection != traitCollection.layoutDirection
            || previousTraitCollection.displayScale != traitCollection.displayScale
    }
}

public extension XDThemeable where Self: UIViewController {
    var xdThemeResolver: XDThemeResolver {
        xdThemeContext.resolver(compatibleWith: traitCollection)
    }

    func xdThemeColor(_ token: XDColorToken) -> UIColor { xdThemeResolver.color(token) }
    func xdThemeFont(_ token: XDFontToken) -> UIFont { xdThemeResolver.font(token) }

    func xdNeedsThemeUpdate(after previousTraitCollection: UITraitCollection?) -> Bool {
        guard let previousTraitCollection else { return true }
        return previousTraitCollection.hasDifferentColorAppearance(comparedTo: traitCollection)
            || previousTraitCollection.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory
            || previousTraitCollection.layoutDirection != traitCollection.layoutDirection
            || previousTraitCollection.displayScale != traitCollection.displayScale
    }
}
