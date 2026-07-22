import Foundation

/// Search/channel advertising surface (`/api/search_ads/…`).
/// Access via ``SDKClient/searchAds``.
public struct SDKSearchAdsAPI: Sendable {
    let http: SDKHTTPClient

    /// Create a channel and its order in one call.
    /// `POST /api/search_ads/order/create/`
    @discardableResult
    public func createOrder(_ order: SDKCreateChannelOrder) async throws -> SDKResponseMessage {
        let endpoint = SDKEndpoint(
            method: .post,
            path: "search_ads/order/create/",
            body: .json(try SDKCoding.encode(order)),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKResponseMessage.self)
    }

    /// Detailed info for one order. `GET /api/search_ads/order/{id}/detail/`
    public func detail(orderId: UUID) async throws -> SDKOrderDetail {
        let endpoint = SDKEndpoint(
            method: .get,
            path: "search_ads/order/\(orderId.uuidString.lowercased())/detail/",
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKOrderDetail.self)
    }

    /// Cancel an order. `POST /api/search_ads/order/{id}/cancel/`
    @discardableResult
    public func cancel(orderId: UUID) async throws -> SDKResponseMessage {
        let endpoint = SDKEndpoint(
            method: .post,
            path: "search_ads/order/\(orderId.uuidString.lowercased())/cancel/",
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKResponseMessage.self)
    }

    /// Activate or deactivate an order. `POST /api/search_ads/order/change_status/`
    @discardableResult
    public func setActive(orderId: UUID, isActive: Bool) async throws -> SDKResponseMessage {
        let body = SDKOrderActivation(orderId: orderId, isActive: isActive)
        let endpoint = SDKEndpoint(
            method: .post,
            path: "search_ads/order/change_status/",
            body: .json(try SDKCoding.encode(body)),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKResponseMessage.self)
    }

    /// Register a click on an order. `POST /api/search_ads/order/click/`
    @discardableResult
    public func click(orderId: UUID, viewerId: String) async throws -> SDKResponseMessage {
        let body = SDKClickOrder(orderId: orderId, viewerId: viewerId)
        let endpoint = SDKEndpoint(
            method: .post,
            path: "search_ads/order/click/",
            body: .json(try SDKCoding.encode(body)),
            requiresAuth: true,
            sendsApiKey: true
        )
        return try await http.send(endpoint, as: SDKResponseMessage.self)
    }

    /// Find a channel by tag for a viewer. `POST /api/search_ads/order/search/`
    public func search(tag: String, viewerId: String) async throws -> SDKSearchResult {
        let body = SDKSearchRequest(tag: tag, viewerId: viewerId)
        let endpoint = SDKEndpoint(
            method: .post,
            path: "search_ads/order/search/",
            body: .json(try SDKCoding.encode(body)),
            requiresAuth: true,
            sendsApiKey: true
        )
        return try await http.send(endpoint, as: SDKSearchResult.self)
    }

    /// The current user's active orders. `GET /api/search_ads/orders/active/`
    public func activeOrders(page: Int? = nil, pageSize: Int? = nil) async throws -> SDKPaginated<SDKOrderDetail> {
        let endpoint = SDKEndpoint(
            method: .get,
            path: "search_ads/orders/active/",
            query: SDKQuery.pagination(page: page, pageSize: pageSize),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKPaginated<SDKOrderDetail>.self)
    }

    /// All of the current user's orders. `GET /api/search_ads/orders/all/`
    public func allOrders(page: Int? = nil, pageSize: Int? = nil) async throws -> SDKPaginated<SDKOrderDetail> {
        let endpoint = SDKEndpoint(
            method: .get,
            path: "search_ads/orders/all/",
            query: SDKQuery.pagination(page: page, pageSize: pageSize),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKPaginated<SDKOrderDetail>.self)
    }
}
