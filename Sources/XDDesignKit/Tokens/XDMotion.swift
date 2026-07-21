import UIKit

public enum XDMotion {
    public static func style(_ token: XDMotionToken, theme: XDTheme) -> XDMotionStyle {
        theme.metrics.motion(for: token)
    }

    /// Returns zero-duration motion when Reduce Motion is enabled.
    @MainActor
    public static func resolved(
        _ token: XDMotionToken,
        resolver: XDThemeResolver
    ) -> XDMotionStyle {
        guard !UIAccessibility.isReduceMotionEnabled else {
            return XDMotionStyle(duration: 0, curve: .linear)
        }
        return resolver.motion(token)
    }
}
