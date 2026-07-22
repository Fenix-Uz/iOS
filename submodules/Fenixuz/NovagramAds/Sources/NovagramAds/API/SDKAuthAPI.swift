import Foundation

/// Authentication surface: login, register, refresh, verify, profile, logout.
/// Access via ``SDKClient/auth``.
public struct SDKAuthAPI: Sendable {
    let http: SDKHTTPClient
    let authProvider: SDKAuthProvider

    /// Obtain and store an access/refresh token pair.
    /// `POST /api/auth/login/`
    @discardableResult
    public func login(username: String, password: String) async throws -> SDKTokenPair {
        try await authProvider.login(username: username, password: password)
    }

    /// Register a new account. Does not log in — call ``login(username:password:)``
    /// afterwards. `POST /api/auth/register/`
    @discardableResult
    public func register(
        username: String,
        password: String,
        passwordConfirmation: String,
        email: String? = nil
    ) async throws -> SDKRegisteredUser {
        let body = SDKRegisterRequest(
            username: username,
            password: password,
            password2: passwordConfirmation,
            email: email
        )
        let endpoint = SDKEndpoint(
            method: .post,
            path: "auth/register/",
            body: .json(try SDKCoding.encode(body)),
            requiresAuth: false
        )
        return try await http.send(endpoint, as: SDKRegisteredUser.self)
    }

    /// Force a token refresh and return the new access token.
    /// `POST /api/auth/refresh/`
    @discardableResult
    public func refresh() async throws -> String {
        try await authProvider.refresh()
    }

    /// Check whether a token is currently valid. Returns `false` for a rejected
    /// token rather than throwing. `POST /api/auth/verify/`
    public func verify(token: String) async throws -> Bool {
        let endpoint = SDKEndpoint(
            method: .post,
            path: "auth/verify/",
            body: .json(try SDKCoding.encode(SDKVerifyRequest(token: token))),
            requiresAuth: false
        )
        do {
            try await http.sendIgnoringBody(endpoint)
            return true
        } catch SDKError.unauthorized {
            return false
        } catch SDKError.http(let status, _, _) where status == 401 || status == 400 {
            return false
        }
    }

    /// The authenticated user's profile. `GET /api/auth/profile/`
    public func profile() async throws -> SDKUserProfile {
        let endpoint = SDKEndpoint(method: .get, path: "auth/profile/", requiresAuth: true)
        return try await http.send(endpoint, as: SDKUserProfile.self)
    }

    /// Clear the local session and persisted tokens.
    public func logout() async {
        await authProvider.logout()
    }

    // MARK: Wire payloads

    private struct SDKRegisterRequest: Encodable {
        let username: String
        let password: String
        let password2: String
        let email: String?
    }

    private struct SDKVerifyRequest: Encodable {
        let token: String
    }
}
