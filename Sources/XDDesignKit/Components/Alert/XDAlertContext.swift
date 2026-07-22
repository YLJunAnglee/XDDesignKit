import Foundation

/// A presentation failure reported without falling back to a global window or
/// changing behavior between Debug and Release builds.
public struct XDAlertPresentationFailure: RawRepresentable, Error, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        precondition(!rawValue.isEmpty, "An alert presentation failure must not be empty")
        self.rawValue = rawValue
    }

    public static let presenterNotAttachedToScene = XDAlertPresentationFailure(
        rawValue: "presenterNotAttachedToScene"
    )
    public static let presenterUnavailable = XDAlertPresentationFailure(
        rawValue: "presenterUnavailable"
    )
    public static let presentationRejected = XDAlertPresentationFailure(
        rawValue: "presentationRejected"
    )
}

/// A lightweight reference to a presented alert. It intentionally never exposes its controller.
@MainActor
public final class XDAlertHandle {
    weak var controller: XDAlertViewController?
    public private(set) var presentationFailure: XDAlertPresentationFailure?

    init(controller: XDAlertViewController? = nil) {
        self.controller = controller
    }

    public var isPresented: Bool {
        guard let controller else { return false }
        return controller.presentingViewController != nil && !controller.isBeingDismissed
    }

    public func dismiss(animated: Bool = true) {
        controller?.dismissAlert(animated: animated)
    }

    func markPresentationFailed(_ failure: XDAlertPresentationFailure) {
        guard presentationFailure == nil else { return }
        presentationFailure = failure
        controller = nil
    }
}

/// Values and controls available to an alert action handler.
@MainActor
public final class XDAlertActionContext {
    private weak var controller: XDAlertViewController?
    private let actionIndex: Int

    init(controller: XDAlertViewController, actionIndex: Int) {
        self.controller = controller
        self.actionIndex = actionIndex
    }

    public var checkboxIsSelected: Bool? {
        controller?.checkboxIsSelected
    }

    public var textFieldText: String? {
        controller?.textFieldText
    }

    public func dismiss(animated: Bool = true) {
        controller?.dismissAlert(animated: animated)
    }

    public func setLoading(_ isLoading: Bool) {
        controller?.setActionLoading(isLoading, at: actionIndex)
    }
}
