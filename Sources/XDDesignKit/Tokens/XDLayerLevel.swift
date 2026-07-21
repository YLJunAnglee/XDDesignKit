import UIKit

/// Semantic ordering inside one presentation container. These values do not
/// order views across windows; overlays must still use a scene-owned presenter.
public enum XDLayerLevel {
    public static let content: CGFloat = 0
    public static let sticky: CGFloat = 100
    public static let overlay: CGFloat = 1_000
    public static let toast: CGFloat = 1_100
    public static let alert: CGFloat = 1_200
}
