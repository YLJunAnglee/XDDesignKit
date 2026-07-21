import UIKit

/// A thread-safe theme scope. Mutations are main-actor isolated; immutable
/// snapshots may be read from dynamic UIColor providers.
public final class XDThemeContext: @unchecked Sendable {
    private let lock = NSLock()
    private var storedTheme: XDTheme

    public var currentTheme: XDTheme {
        lock.lock()
        defer { lock.unlock() }
        return storedTheme
    }

    public init() {
        self.storedTheme = .defaultTheme
    }

    public init(initialTheme: XDTheme) throws {
        let result = initialTheme.validationResult()
        guard result.isValid else { throw XDThemeValidationError(result: result) }
        self.storedTheme = initialTheme
    }

    @MainActor
    @discardableResult
    public func apply(_ theme: XDTheme) throws -> XDThemeValidationResult {
        let result = theme.validationResult()
        guard result.isValid else { throw XDThemeValidationError(result: result) }

        lock.lock()
        storedTheme = theme
        lock.unlock()
        NotificationCenter.default.post(
            name: .xdThemeDidChange,
            object: self,
            userInfo: [XDThemeNotificationKey.themeIdentifier: theme.identifier]
        )
        return result
    }

    public func color(for token: XDColorToken, compatibleWith traitCollection: UITraitCollection) -> UIColor {
        currentTheme.color(for: token, compatibleWith: traitCollection)
    }

    public func resolver(compatibleWith traitCollection: UITraitCollection) -> XDThemeResolver {
        XDThemeResolver(theme: currentTheme, traitCollection: traitCollection)
    }

    public func dynamicColor(_ token: XDColorToken) -> UIColor {
        UIColor(dynamicProvider: { [weak self] traits in
            guard let self else { return .clear }
            return self.color(for: token, compatibleWith: traits)
        })
    }
}

@MainActor
public final class XDThemeManager {
    public static let shared = XDThemeManager()
    public let globalContext: XDThemeContext
    public var currentTheme: XDTheme { globalContext.currentTheme }

    private init() {
        self.globalContext = XDThemeContext()
    }

    @discardableResult
    public func apply(_ theme: XDTheme) throws -> XDThemeValidationResult {
        try globalContext.apply(theme)
    }

    public func color(for token: XDColorToken, compatibleWith traitCollection: UITraitCollection) -> UIColor {
        globalContext.color(for: token, compatibleWith: traitCollection)
    }
}

public enum XDThemeNotificationKey: Sendable {
    public static let themeIdentifier = "XDThemeIdentifier"
}

public extension Notification.Name {
    static let xdThemeDidChange = Notification.Name("XDDesignKit.themeDidChange")

    @available(*, deprecated, renamed: "xdThemeDidChange")
    static let XDThemeDidChange = xdThemeDidChange
}
