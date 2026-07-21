import UIKit

/// A theme-driven gradient specification used by button appearances.
public struct XDButtonGradient: Sendable {
    public let colorTokens: [XDColorToken]
    public let startPoint: CGPoint
    public let endPoint: CGPoint

    public init(
        colorTokens: [XDColorToken],
        startPoint: CGPoint = CGPoint(x: 0, y: 0.5),
        endPoint: CGPoint = CGPoint(x: 1, y: 0.5)
    ) {
        precondition(colorTokens.count >= 2, "A button gradient requires at least two colors")
        self.colorTokens = colorTokens
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
}

/// Extensible background description without exposing an exhaustive public enum.
public struct XDButtonBackground: Sendable {
    enum Storage: Sendable {
        case clear
        case solid(XDColorToken)
        case gradient(XDButtonGradient)
    }

    let storage: Storage

    public static let clear = XDButtonBackground(storage: .clear)

    public static func solid(_ colorToken: XDColorToken) -> XDButtonBackground {
        XDButtonBackground(storage: .solid(colorToken))
    }

    public static func gradient(_ gradient: XDButtonGradient) -> XDButtonBackground {
        XDButtonBackground(storage: .gradient(gradient))
    }

    var isValid: Bool {
        switch storage {
        case .clear, .solid:
            return true
        case let .gradient(gradient):
            return gradient.colorTokens.count >= 2
                && gradient.startPoint.x.isFinite
                && gradient.startPoint.y.isFinite
                && gradient.endPoint.x.isFinite
                && gradient.endPoint.y.isFinite
        }
    }
}

@MainActor
final class XDButtonBackgroundRenderer {
    private let gradientLayer = CAGradientLayer()

    func apply(
        _ background: XDButtonBackground,
        to button: UIButton,
        resolver: XDThemeResolver,
        buttonTheme: XDButtonTheme,
        cornerRadius: CGFloat
    ) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        switch background.storage {
        case .clear:
            button.backgroundColor = .clear
            removeGradientLayer()
        case let .solid(token):
            button.backgroundColor = buttonTheme.color(for: token, resolver: resolver)
            removeGradientLayer()
        case let .gradient(gradient):
            button.backgroundColor = .clear
            gradientLayer.colors = gradient.colorTokens.map {
                buttonTheme.color(for: $0, resolver: resolver).cgColor
            }
            gradientLayer.startPoint = gradient.startPoint
            gradientLayer.endPoint = gradient.endPoint
            gradientLayer.cornerRadius = cornerRadius
            if gradientLayer.superlayer !== button.layer {
                gradientLayer.removeFromSuperlayer()
                button.layer.insertSublayer(gradientLayer, at: 0)
            }
        }
    }

    func layout(in bounds: CGRect, cornerRadius: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = cornerRadius
        CATransaction.commit()
    }

    private func removeGradientLayer() {
        gradientLayer.removeFromSuperlayer()
        gradientLayer.colors = nil
    }
}
