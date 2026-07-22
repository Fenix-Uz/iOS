import Foundation

/// Controls automatic retries for *idempotent* requests (GET/PUT/DELETE) that
/// fail with a transport error or a 5xx status. Non-idempotent requests
/// (POST/PATCH) are never retried, so orders are never accidentally duplicated.
public struct SDKRetryPolicy: Hashable, Sendable {
    /// Number of *additional* attempts after the first one. `0` disables retry.
    public var maxRetries: Int

    /// Base delay for exponential backoff; attempt *n* waits
    /// `baseDelay * 2^(n-1)` seconds.
    public var baseDelay: TimeInterval

    /// Upper bound on any single backoff wait.
    public var maxDelay: TimeInterval

    public init(maxRetries: Int = 2, baseDelay: TimeInterval = 0.5, maxDelay: TimeInterval = 8) {
        self.maxRetries = max(0, maxRetries)
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }

    /// A sensible default: up to two retries with 0.5s → 1s backoff.
    public static let `default` = SDKRetryPolicy()

    /// Disable retries entirely.
    public static let none = SDKRetryPolicy(maxRetries: 0)

    func delay(forAttempt attempt: Int) -> TimeInterval {
        let exponential = baseDelay * pow(2, Double(max(0, attempt - 1)))
        return min(exponential, maxDelay)
    }
}
