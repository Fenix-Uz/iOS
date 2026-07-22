import Foundation

/// Whether a channel has been claimed by its owner in the partner program.
/// Forward-compatible: an unrecognized value decodes into ``unknown(_:)``.
public enum SDKClaimStatus: Hashable, Sendable, Codable {
    /// Not yet claimed (`UNCLAIMED`).
    case unclaimed
    /// Ownership confirmed (`CONFIRMED`).
    case confirmed
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .unclaimed: return "UNCLAIMED"
        case .confirmed: return "CONFIRMED"
        case .unknown(let value): return value
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "UNCLAIMED": self = .unclaimed
        case "CONFIRMED": self = .confirmed
        default: self = .unknown(rawValue)
        }
    }

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self.init(rawValue: raw)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
