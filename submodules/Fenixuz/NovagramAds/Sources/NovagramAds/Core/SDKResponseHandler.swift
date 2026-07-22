import Foundation

/// Maps a raw `(Data, HTTPURLResponse)` pair into either a decoded model or a
/// typed ``SDKError``. Centralizing this means every endpoint reports errors
/// the same way.
enum SDKResponseHandler {
    /// Decode a 2xx body into `T`, or throw the appropriate ``SDKError``.
    static func decode<T: Decodable>(
        _ type: T.Type,
        data: Data,
        response: HTTPURLResponse
    ) throws -> T {
        try ensureSuccess(data: data, response: response)
        guard !data.isEmpty else {
            throw SDKError.decoding(message: "Expected \(T.self) but the response body was empty.")
        }
        do {
            return try SDKCoding.makeDecoder().decode(T.self, from: data)
        } catch let error as SDKError {
            throw error
        } catch {
            throw SDKError.decoding(message: Self.describe(error))
        }
    }

    /// Validate a response whose body is intentionally ignored (used for calls
    /// where the caller only cares about success).
    static func ensureSuccess(data: Data, response: HTTPURLResponse) throws {
        let status = response.statusCode
        guard !(200..<300).contains(status) else { return }

        if status == 401 {
            throw SDKError.unauthorized(detail: parseDetail(data))
        }
        if status == 400, let fields = parseFieldErrors(data) {
            throw SDKError.validation(fields: fields, status: status)
        }
        throw SDKError.http(
            status: status,
            detail: parseDetail(data),
            body: String(data: data, encoding: .utf8) ?? ""
        )
    }

    // MARK: - Error body parsing

    private struct DetailEnvelope: Decodable { let detail: String }
    private struct ErrorEnvelope: Decodable { let error: String }

    /// The server surfaces a human message under `{"detail": …}` (DRF / SimpleJWT)
    /// or, on some endpoints, `{"error": …}`. Try both.
    static func parseDetail(_ data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        if let detail = try? JSONDecoder().decode(DetailEnvelope.self, from: data).detail {
            return detail
        }
        return try? JSONDecoder().decode(ErrorEnvelope.self, from: data).error
    }

    /// DRF field errors look like `{"field": ["msg", …]}`. Returns `nil` when the
    /// body is not shaped that way (so the caller can fall back to a generic error).
    static func parseFieldErrors(_ data: Data) -> [String: [String]]? {
        guard !data.isEmpty,
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        // A top-level `{"error": "…"}` is a general API error, not DRF field
        // errors — let it fall through to `.http` with the message as `detail`.
        if object.count == 1, object["error"] is String { return nil }

        var result: [String: [String]] = [:]
        for (key, value) in object {
            switch value {
            case let strings as [String]:
                result[key] = strings
            case let single as String:
                result[key] = [single]
            default:
                // A non-string-array value (e.g. the `detail` envelope) means
                // this isn't a field-error body.
                return nil
            }
        }
        return result.isEmpty ? nil : result
    }

    private static func describe(_ error: Error) -> String {
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .keyNotFound(let key, let context):
                return "Missing key '\(key.stringValue)' at \(path(context)). \(context.debugDescription)"
            case .typeMismatch(let type, let context):
                return "Type mismatch for \(type) at \(path(context)). \(context.debugDescription)"
            case .valueNotFound(let type, let context):
                return "Missing value for \(type) at \(path(context)). \(context.debugDescription)"
            case .dataCorrupted(let context):
                return "Corrupted data at \(path(context)). \(context.debugDescription)"
            @unknown default:
                return String(describing: decodingError)
            }
        }
        return error.localizedDescription
    }

    private static func path(_ context: DecodingError.Context) -> String {
        let joined = context.codingPath.map(\.stringValue).joined(separator: ".")
        return joined.isEmpty ? "<root>" : joined
    }
}
