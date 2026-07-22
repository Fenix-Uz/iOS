import Foundation

/// Every error surfaced by the SDK is one of these cases, so callers can
/// `catch` precisely instead of string-matching. Prefixed with `SDK` to avoid
/// clashing with a host app's own `APIError`/`NetworkError`.
public enum SDKError: Error, Hashable, Sendable {
    /// The base URL / request could not be assembled into a valid `URL`.
    case invalidRequest(reason: String)

    /// The transport failed before an HTTP response was produced
    /// (no connectivity, TLS failure, timeout, cancellation).
    case transport(message: String)

    /// A response arrived but was not an `HTTPURLResponse`.
    case invalidResponse

    /// Authentication is required but no valid token is available, or a token
    /// refresh ultimately failed. `detail` echoes the server message if any.
    case unauthorized(detail: String?)

    /// A `400` with DRF field-level validation errors:
    /// `{ "channel_id": ["This field is required."] }`.
    case validation(fields: [String: [String]], status: Int)

    /// Any other non-2xx status. `detail` is the parsed `{"detail": …}` message
    /// when present; `body` is the raw response text for diagnostics.
    case http(status: Int, detail: String?, body: String)

    /// The 2xx body could not be decoded into the expected model.
    case decoding(message: String)

    /// A human-readable description suitable for logs (never leaks tokens).
    public var errorDescription: String {
        switch self {
        case .invalidRequest(let reason):
            return "Invalid request: \(reason)"
        case .transport(let message):
            return "Transport error: \(message)"
        case .invalidResponse:
            return "The server returned a non-HTTP response."
        case .unauthorized(let detail):
            return "Unauthorized\(detail.map { ": \($0)" } ?? ".")"
        case .validation(let fields, let status):
            let joined = fields
                .map { "\($0.key): \($0.value.joined(separator: ", "))" }
                .sorted()
                .joined(separator: "; ")
            return "Validation failed (\(status)): \(joined)"
        case .http(let status, let detail, _):
            return "HTTP \(status)\(detail.map { ": \($0)" } ?? ".")"
        case .decoding(let message):
            return "Failed to decode response: \(message)"
        }
    }
}

extension SDKError: CustomStringConvertible {
    public var description: String { errorDescription }
}
