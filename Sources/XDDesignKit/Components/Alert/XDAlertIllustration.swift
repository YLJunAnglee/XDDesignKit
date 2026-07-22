import UIKit

/// Illustration and supporting text used by a celebratory or educational alert.
@MainActor
public struct XDAlertIllustration {
    public let image: UIImage
    public let caption: String?
    public let accessibilityLabel: String?

    public init(
        image: UIImage,
        caption: String? = nil,
        accessibilityLabel: String? = nil
    ) {
        self.image = image
        self.caption = caption
        self.accessibilityLabel = accessibilityLabel
    }
}
