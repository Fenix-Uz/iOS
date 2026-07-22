import Foundation

/// The advertising platform an order runs on. Forward-compatible: an
/// unrecognized value from the server decodes into ``unknown(_:)`` instead of
/// failing, so a platform added server-side never breaks decoding.
public enum SDKPlatform: Hashable, Sendable, Codable {
    case telegram
    case novagram
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .telegram: return "TELEGRAM"
        case .novagram: return "NOVAGRAM"
        case .unknown(let value): return value
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "TELEGRAM": self = .telegram
        case "NOVAGRAM": self = .novagram
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
