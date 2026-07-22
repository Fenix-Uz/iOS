import Foundation

/// A precise decimal value that the API represents inconsistently — some
/// fields arrive as JSON strings (`"2.00"`, `"10.00"`) and others as raw JSON
/// numbers (`9.99`, `9.978`). This type decodes from *either* shape and always
/// re-encodes as a string, which is what every write endpoint expects.
///
/// The underlying value is kept as a `Decimal` to avoid binary floating-point
/// rounding on monetary amounts. `Hashable`/`Equatable`/`Sendable` are
/// synthesized, so models embedding this type stay value-comparable.
public struct SDKDecimalString: Hashable, Sendable, Codable, CustomStringConvertible,
                               ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
    /// The exact decimal value.
    public let value: Decimal

    public init(_ value: Decimal) {
        self.value = value
    }

    /// Create from a decimal string such as `"10.50"`. Falls back to zero when
    /// the string is not a valid number (never traps).
    public init(string: String) {
        self.value = Decimal(string: string, locale: SDKDecimalString.posix) ?? .zero
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(string: value)
    }

    public init(integerLiteral value: IntegerLiteralType) {
        self.value = Decimal(value)
    }

    /// Locale-independent string form using a `.` decimal separator, suitable
    /// for sending back to the API.
    public var stringValue: String {
        NSDecimalNumber(decimal: value).description(withLocale: SDKDecimalString.posix)
    }

    public var doubleValue: Double {
        NSDecimalNumber(decimal: value).doubleValue
    }

    public var description: String { stringValue }

    // MARK: Codable

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self.value = Decimal(string: string, locale: SDKDecimalString.posix) ?? .zero
        } else if let double = try? container.decode(Double.self) {
            // Route through the shortest round-trippable string so a value like
            // 9.978 stays 9.978 rather than picking up float noise.
            self.value = Decimal(string: SDKDecimalString.shortestString(for: double),
                                 locale: SDKDecimalString.posix) ?? Decimal(double)
        } else {
            throw DecodingError.typeMismatch(
                SDKDecimalString.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected a decimal encoded as a JSON string or number."
                )
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }

    // MARK: Helpers

    private static let posix = Locale(identifier: "en_US_POSIX")

    private static func shortestString(for double: Double) -> String {
        String(double)
    }
}
