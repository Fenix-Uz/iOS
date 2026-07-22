import Foundation

/// Balance surface. Access via ``SDKClient/balance``.
public struct SDKBalanceAPI: Sendable {
    let http: SDKHTTPClient

    /// The current user's balance. `GET /api/balance/`
    public func current() async throws -> SDKBalance {
        let endpoint = SDKEndpoint(method: .get, path: "balance/", requiresAuth: true)
        return try await http.send(endpoint, as: SDKBalance.self)
    }
}
