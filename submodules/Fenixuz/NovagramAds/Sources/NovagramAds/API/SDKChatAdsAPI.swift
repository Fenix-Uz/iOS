import Foundation

/// In-chat advertising surface (`/api/chat_ads/…`). Access via ``SDKClient/chatAds``.
public struct SDKChatAdsAPI: Sendable {
    let http: SDKHTTPClient

    // MARK: Media

    /// Upload a photo or video and receive its media id, to be passed as
    /// `mediaId` when creating an order. `POST /api/chat_ads/order/add_media/`
    public func addMedia(data: Data, filename: String, mimeType: String? = nil) async throws -> SDKChatAdMedia {
        var form = SDKMultipartFormData()
        form.addFile(
            name: "file",
            filename: filename,
            mimeType: mimeType ?? SDKMimeType.forFilename(filename),
            data: data
        )
        let endpoint = SDKEndpoint(
            method: .post,
            path: "chat_ads/order/add_media/",
            body: .raw(form.encoded(), contentType: form.contentType),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKChatAdMedia.self)
    }

    /// Upload media from a file on disk.
    public func addMedia(fileURL: URL) async throws -> SDKChatAdMedia {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw SDKError.invalidRequest(reason: "Could not read file at \(fileURL.path): \(error.localizedDescription)")
        }
        return try await addMedia(data: data, filename: fileURL.lastPathComponent)
    }

    // MARK: Orders

    /// Create a chat-ad order and pay for it. `POST /api/chat_ads/order/create/`
    @discardableResult
    public func createOrder(_ order: SDKChatAdOrderCreate) async throws -> SDKResponseMessage {
        let endpoint = SDKEndpoint(
            method: .post,
            path: "chat_ads/order/create/",
            body: .json(try SDKCoding.encode(order)),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKResponseMessage.self)
    }

    /// Detailed info for one order. `GET /api/chat_ads/order/{id}/detail/`
    public func detail(orderId: UUID) async throws -> SDKChatAdOrder {
        let endpoint = SDKEndpoint(
            method: .get,
            path: "chat_ads/order/\(orderId.uuidString.lowercased())/detail/",
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKChatAdOrder.self)
    }

    /// Cancel an order. `POST /api/chat_ads/order/{id}/cancel/`
    @discardableResult
    public func cancel(orderId: UUID) async throws -> SDKResponseMessage {
        let endpoint = SDKEndpoint(
            method: .post,
            path: "chat_ads/order/\(orderId.uuidString.lowercased())/cancel/",
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKResponseMessage.self)
    }

    /// Activate or deactivate an order. `POST /api/chat_ads/order/change_status/`
    @discardableResult
    public func setActive(orderId: UUID, isActive: Bool) async throws -> SDKResponseMessage {
        let body = SDKOrderActivation(orderId: orderId, isActive: isActive)
        let endpoint = SDKEndpoint(
            method: .post,
            path: "chat_ads/order/change_status/",
            body: .json(try SDKCoding.encode(body)),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKResponseMessage.self)
    }

    /// Register a click on an order. `POST /api/chat_ads/order/click/`
    @discardableResult
    public func click(orderId: UUID, viewerId: String) async throws -> SDKResponseMessage {
        let body = SDKClickOrder(orderId: orderId, viewerId: viewerId)
        let endpoint = SDKEndpoint(
            method: .post,
            path: "chat_ads/order/click/",
            body: .json(try SDKCoding.encode(body)),
            requiresAuth: true,
            sendsApiKey: true
        )
        return try await http.send(endpoint, as: SDKResponseMessage.self)
    }

    /// Fetch an ad to display in a channel. `POST /api/chat_ads/order/search/`
    public func search(channelName: String, viewerId: String, channelId: Int64? = nil) async throws -> SDKChatAdSearch {
        let body = SDKAdRequest(channelName: channelName, viewerId: viewerId, channelId: channelId)
        let endpoint = SDKEndpoint(
            method: .post,
            path: "chat_ads/order/search/",
            body: .json(try SDKCoding.encode(body)),
            requiresAuth: true,
            sendsApiKey: true
        )
        return try await http.send(endpoint, as: SDKChatAdSearch.self)
    }

    /// The current user's active orders. `GET /api/chat_ads/orders/active/`
    public func activeOrders(page: Int? = nil, pageSize: Int? = nil) async throws -> SDKPaginated<SDKChatAdOrder> {
        let endpoint = SDKEndpoint(
            method: .get,
            path: "chat_ads/orders/active/",
            query: SDKQuery.pagination(page: page, pageSize: pageSize),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKPaginated<SDKChatAdOrder>.self)
    }

    /// All of the current user's orders. `GET /api/chat_ads/orders/all/`
    public func allOrders(page: Int? = nil, pageSize: Int? = nil) async throws -> SDKPaginated<SDKChatAdOrder> {
        let endpoint = SDKEndpoint(
            method: .get,
            path: "chat_ads/orders/all/",
            query: SDKQuery.pagination(page: page, pageSize: pageSize),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKPaginated<SDKChatAdOrder>.self)
    }
}
