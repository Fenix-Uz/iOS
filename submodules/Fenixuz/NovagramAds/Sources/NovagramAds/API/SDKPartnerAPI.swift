import Foundation

/// Channel-owner partner program (`/api/partner/…`). Channel owners claim their
/// channels, watch earnings accrue from paid impressions, and withdraw the
/// available balance. Access via ``SDKClient/partner``.
public struct SDKPartnerAPI: Sendable {
    let http: SDKHTTPClient

    /// Public earnings showcase for a channel — how much it has already earned.
    /// `GET /api/partner/earnings/?channel_id=<id>`
    ///
    /// Works with or without a logged-in session. The `channel_id` query
    /// parameter is required by the server even though the OpenAPI spec omits it.
    public func earnings(channelId: Int64) async throws -> SDKPublicEarning {
        let endpoint = SDKEndpoint(
            method: .get,
            path: "partner/earnings/",
            query: [URLQueryItem(name: "channel_id", value: String(channelId))],
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKPublicEarning.self)
    }

    /// The authenticated owner's confirmed channels and their earnings.
    /// `GET /api/partner/my/`
    public func myEarnings(page: Int? = nil, pageSize: Int? = nil) async throws -> SDKPaginated<SDKMyEarning> {
        let endpoint = SDKEndpoint(
            method: .get,
            path: "partner/my/",
            query: SDKQuery.pagination(page: page, pageSize: pageSize),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKPaginated<SDKMyEarning>.self)
    }

    /// Claim ownership of a channel to start earning from ads shown on it.
    /// `POST /api/partner/claim/`
    @discardableResult
    public func claim(channelId: Int64, channelName: String? = nil) async throws -> SDKResponseMessage {
        let body = SDKClaimRequest(channelId: channelId, channelName: channelName)
        let endpoint = SDKEndpoint(
            method: .post,
            path: "partner/claim/",
            body: .json(try SDKCoding.encode(body)),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKResponseMessage.self)
    }

    /// Withdraw the available balance for a claimed channel.
    /// `POST /api/partner/withdraw/`
    @discardableResult
    public func withdraw(channelId: Int64) async throws -> SDKResponseMessage {
        let body = SDKWithdrawRequest(channelId: channelId)
        let endpoint = SDKEndpoint(
            method: .post,
            path: "partner/withdraw/",
            body: .json(try SDKCoding.encode(body)),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKResponseMessage.self)
    }

    // MARK: Wire payloads

    private struct SDKClaimRequest: Encodable {
        let channelId: Int64
        let channelName: String?
    }

    private struct SDKWithdrawRequest: Encodable {
        let channelId: Int64
    }
}
