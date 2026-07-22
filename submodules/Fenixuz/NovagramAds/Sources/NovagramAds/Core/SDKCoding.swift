import Foundation

/// Factory for the JSON coders shared across the SDK.
///
/// Key strategy: snake_case ⇄ camelCase, so Swift models use idiomatic
/// `orderName` while the wire stays `order_name` — no per-model `CodingKeys`
/// boilerplate. Date strategy: the dual ISO-8601 parser in ``SDKDate``.
///
/// Fresh instances are cheap relative to a network round-trip and sidestep any
/// `Sendable` concerns about sharing a mutable coder across tasks.
enum SDKCoding {
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            guard let date = SDKDate.date(from: raw) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unrecognized ISO-8601 date: \(raw)"
                )
            }
            return date
        }
        return decoder
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(SDKDate.string(from: date))
        }
        return encoder
    }

    /// Encode a request body, mapping any failure to ``SDKError/invalidRequest(reason:)``.
    static func encode<T: Encodable>(_ value: T) throws -> Data {
        do {
            return try makeEncoder().encode(value)
        } catch {
            throw SDKError.invalidRequest(reason: "Failed to encode request body: \(error)")
        }
    }
}
