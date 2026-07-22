import Foundation

/// Owns the session's token state and the two endpoints that issue tokens
/// (login + refresh). An `actor` so token reads/writes and — crucially — the
/// refresh flow are serialized: many concurrent requests hitting a `401` at
/// once collapse into a *single* refresh call rather than a stampede.
public actor SDKAuthProvider {
    private let executor: SDKRequestExecutor
    private let store: SDKTokenStore
    private var tokens: SDKTokenPair?
    private var refreshTask: Task<String, Error>?

    init(executor: SDKRequestExecutor, store: SDKTokenStore) {
        self.executor = executor
        self.store = store
        self.tokens = store.restore()
    }

    // MARK: State

    /// Whether a token pair is currently held (does not verify it server-side).
    public var isAuthenticated: Bool { tokens != nil }

    /// The current pair, if any.
    public var currentTokens: SDKTokenPair? { tokens }

    var accessToken: String? { tokens?.access }

    /// Inject externally obtained tokens (e.g. restored from your own storage).
    public func setTokens(_ tokens: SDKTokenPair) {
        self.tokens = tokens
        store.persist(tokens)
    }

    /// Drop the session and clear persisted tokens.
    public func logout() {
        tokens = nil
        refreshTask?.cancel()
        refreshTask = nil
        store.persist(nil)
    }

    /// Force a token refresh now and return the new access token. Useful for
    /// proactively renewing before a batch of requests.
    @discardableResult
    public func refresh() async throws -> String {
        try await validAccessToken(replacing: tokens?.access)
    }

    // MARK: Login

    func login(username: String, password: String) async throws -> SDKTokenPair {
        let payload = try SDKCoding.makeEncoder().encode(SDKLoginRequest(username: username, password: password))
        let endpoint = SDKEndpoint(method: .post, path: "auth/login/", body: .json(payload), requiresAuth: false)
        let (data, response) = try await executor.perform(endpoint, accessToken: nil)
        let pair = try SDKResponseHandler.decode(SDKTokenPair.self, data: data, response: response)
        setTokens(pair)
        return pair
    }

    // MARK: Refresh (single-flight)

    /// Return a valid access token, refreshing once if the caller's token was
    /// rejected. Concurrent callers share one in-flight refresh.
    func validAccessToken(replacing failedToken: String?) async throws -> String {
        // Someone may already have refreshed while we were waiting our turn.
        if let current = tokens?.access, current != failedToken {
            return current
        }
        if let inFlight = refreshTask {
            return try await inFlight.value
        }
        guard let refresh = tokens?.refresh else {
            throw SDKError.unauthorized(detail: "No refresh token available; login required.")
        }

        let executor = self.executor
        let task = Task { () throws -> String in
            let payload = try SDKCoding.makeEncoder().encode(SDKRefreshRequest(refresh: refresh))
            let endpoint = SDKEndpoint(method: .post, path: "auth/refresh/", body: .json(payload), requiresAuth: false)
            let (data, response) = try await executor.perform(endpoint, accessToken: nil)
            return try SDKResponseHandler.decode(SDKRefreshResponse.self, data: data, response: response).access
        }
        refreshTask = task

        do {
            let newAccess = try await task.value
            refreshTask = nil
            let updated = SDKTokenPair(access: newAccess, refresh: tokens?.refresh ?? refresh)
            setTokens(updated)
            return newAccess
        } catch is CancellationError {
            refreshTask = nil
            throw CancellationError()
        } catch {
            refreshTask = nil
            // A dead refresh token means the whole session is gone.
            logout()
            throw SDKError.unauthorized(detail: "Session expired; login required.")
        }
    }

    // MARK: Wire payloads

    private struct SDKLoginRequest: Encodable {
        let username: String
        let password: String
    }

    private struct SDKRefreshRequest: Encodable {
        let refresh: String
    }

    private struct SDKRefreshResponse: Decodable {
        let access: String
    }
}
