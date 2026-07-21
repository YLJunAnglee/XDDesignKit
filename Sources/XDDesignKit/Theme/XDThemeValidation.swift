import Foundation

public struct XDThemeValidationResult: Sendable {
    public let errors: [String]

    public init(errors: [String]) {
        self.errors = errors
    }

    public var isValid: Bool { errors.isEmpty }
}

public struct XDThemeValidationError: Error, LocalizedError, Sendable {
    public let result: XDThemeValidationResult

    public init(result: XDThemeValidationResult) {
        self.result = result
    }

    public var errorDescription: String? {
        result.errors.joined(separator: "; ")
    }
}
