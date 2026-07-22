import Foundation

/// The authenticated transport used by every API namespace. Layers three things
/// on top of ``SDKRequestExecutor``:
///   1. bearer-token injection for `requiresAuth` endpoints,
///   2. a single automatic token refresh + replay when a `401` comes back,
///   3. exponential-backoff retries for idempotent requests on transport/5xx failures.
struct SDKHTTPClient: Sendable {
    let executor: SDKRequestExecutor
    let authProvider: SDKAuthProvider
    let retryPolicy: SDKRetryPolicy

    /// Send a request and decode its 2xx body into `T`.
    func send<T: Decodable>(_ endpoint: SDKEndpoint, as type: T.Type) async throws -> T {
        let (data, response) = try await perform(endpoint)
        return try SDKResponseHandler.decode(T.self, data: data, response: response)
    }

    /// Send a request and only assert success (body ignored).
    @discardableResult
    func sendIgnoringBody(_ endpoint: SDKEndpoint) async throws -> HTTPURLResponse {
        let (data, response) = try await perform(endpoint)
        try SDKResponseHandler.ensureSuccess(data: data, response: response)
        return response
    }

    // MARK: - Core

    private func perform(_ endpoint: SDKEndpoint) async throws -> (Data, HTTPURLResponse) {
        let token = endpoint.requiresAuth ? await authProvider.accessToken : nil
        var (data, response) = try await performWithRetry(endpoint, accessToken: token)

        // One reactive refresh on 401, then replay the original request.
        if response.statusCode == 401, endpoint.requiresAuth {
            let refreshed = try await authProvider.validAccessToken(replacing: token)
            (data, response) = try await performWithRetry(endpoint, accessToken: refreshed)
        }
        return (data, response)
    }

    private func performWithRetry(
        _ endpoint: SDKEndpoint,
        accessToken: String?
    ) async throws -> (Data, HTTPURLResponse) {
        var attempt = 0
        while true {
            try Task.checkCancellation()
            do {
                let (data, response) = try await executor.perform(endpoint, accessToken: accessToken)
                if (500...599).contains(response.statusCode),
                   endpoint.method.isIdempotent,
                   attempt < retryPolicy.maxRetries {
                    attempt += 1
                    try await backoff(attempt)
                    continue
                }
                return (data, response)
            } catch let error as SDKError {
                if case .transport = error,
                   endpoint.method.isIdempotent,
                   attempt < retryPolicy.maxRetries {
                    attempt += 1
                    try await backoff(attempt)
                    continue
                }
                throw error
            }
        }
    }

    private func backoff(_ attempt: Int) async throws {
        let seconds = retryPolicy.delay(forAttempt: attempt)
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
