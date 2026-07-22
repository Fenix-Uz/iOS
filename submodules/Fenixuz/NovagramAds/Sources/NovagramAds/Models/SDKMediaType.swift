import Foundation

/// The kind of media attached to a chat ad. Forward-compatible: an unrecognized
/// value from the server decodes into ``unknown(_:)`` instead of failing.
public enum SDKMediaType: Hashable, Sendable, Codable {
    case image
    case video
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .image: return "IMAGE"
        case .video: return "VIDEO"
        case .unknown(let value): return value
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "IMAGE": self = .image
        case "VIDEO": self = .video
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
