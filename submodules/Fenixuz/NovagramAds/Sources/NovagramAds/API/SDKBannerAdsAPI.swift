import Foundation

/// Chat-list banner surface (`/api/banner_ads/…`) — a Telegram-style banner
/// shown above a chat list: title/text/link, an optional dismiss, and a
/// scheduling window. The backend reuses its `announcements` schema under
/// this dedicated route. Access via ``SDKClient/bannerAds``.
///
/// Two trust boundaries, same shape as the ad-serving surface on
/// ``SDKChatAdsAPI``:
///   - ``activeBanners(viewerId:)``, ``click(bannerId:)``, and
///     ``dismiss(bannerId:viewerId:)`` are server-to-server: they send the
///     `X-API-Key` and need **no** bearer token (`requiresAuth: false`).
///   - The `manage*` CRUD needs a bearer token (`requiresAuth: true`) and
///     never sends the API key.
public struct SDKBannerAdsAPI: Sendable {
    let http: SDKHTTPClient

    // MARK: Client / serving (X-API-Key)

    /// Banner ads currently eligible to show a viewer, most relevant first.
    /// `POST /api/banner_ads/active/`
    public func activeBanners(viewerId: String) async throws -> [SDKBannerAd] {
        let endpoint = SDKEndpoint(
            method: .post,
            path: "banner_ads/active/",
            body: .json(try SDKCoding.encode(SDKBannerViewerRequest(viewerId: viewerId))),
            requiresAuth: false,
            sendsApiKey: true
        )
        return try await http.send(endpoint, as: [SDKBannerAd].self)
    }

    /// Register a click on a banner ad. `POST /api/banner_ads/click/`
    ///
    /// - Note: the wire body key is `announcement_id` — the backend reuses its
    ///   announcement schema even though this SDK's parameter is `bannerId`.
    @discardableResult
    public func click(bannerId: UUID) async throws -> SDKResponseMessage {
        let endpoint = SDKEndpoint(
            method: .post,
            path: "banner_ads/click/",
            body: .json(try SDKCoding.encode(SDKBannerClickRequest(announcementId: bannerId))),
            requiresAuth: false,
            sendsApiKey: true
        )
        return try await http.send(endpoint, as: SDKResponseMessage.self)
    }

    /// Dismiss a banner ad so this viewer stops seeing it.
    /// `POST /api/banner_ads/dismiss/`
    @discardableResult
    public func dismiss(bannerId: UUID, viewerId: String) async throws -> SDKResponseMessage {
        let endpoint = SDKEndpoint(
            method: .post,
            path: "banner_ads/dismiss/",
            body: .json(try SDKCoding.encode(SDKBannerDismissRequest(announcementId: bannerId, viewerId: viewerId))),
            requiresAuth: false,
            sendsApiKey: true
        )
        return try await http.send(endpoint, as: SDKResponseMessage.self)
    }

    // MARK: Manage (admin CRUD, JWT)

    /// All banner ads regardless of status, for an admin dashboard.
    /// `GET /api/banner_ads/manage/`
    public func manageList(page: Int? = nil, pageSize: Int? = nil) async throws -> SDKPaginated<SDKBannerAdManage> {
        let endpoint = SDKEndpoint(
            method: .get,
            path: "banner_ads/manage/",
            query: SDKQuery.pagination(page: page, pageSize: pageSize),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKPaginated<SDKBannerAdManage>.self)
    }

    /// Create a banner ad. `title`/`text` are required; every other parameter
    /// is sent only when non-`nil` (omitted, never encoded as JSON `null`).
    /// `POST /api/banner_ads/manage/`
    public func create(
        title: String,
        text: String,
        link: String? = nil,
        dismissible: Bool? = nil,
        isActive: Bool? = nil,
        startsAt: Date? = nil,
        endsAt: Date? = nil,
        priority: Int? = nil
    ) async throws -> SDKBannerAdManage {
        let body = SDKBannerAdCreateRequest(
            title: title,
            text: text,
            link: link,
            dismissible: dismissible,
            isActive: isActive,
            startsAt: startsAt,
            endsAt: endsAt,
            priority: priority
        )
        let endpoint = SDKEndpoint(
            method: .post,
            path: "banner_ads/manage/",
            body: .json(try SDKCoding.encode(body)),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKBannerAdManage.self)
    }

    /// Detailed info for one banner ad. `GET /api/banner_ads/manage/{id}/`
    public func detail(id: UUID) async throws -> SDKBannerAdManage {
        let endpoint = SDKEndpoint(
            method: .get,
            path: "banner_ads/manage/\(id.uuidString.lowercased())/",
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKBannerAdManage.self)
    }

    /// Partially update a banner ad — only the non-`nil` parameters are sent,
    /// so unset fields are left untouched server-side. `PATCH /api/banner_ads/manage/{id}/`
    public func update(
        id: UUID,
        title: String? = nil,
        text: String? = nil,
        link: String? = nil,
        dismissible: Bool? = nil,
        isActive: Bool? = nil,
        startsAt: Date? = nil,
        endsAt: Date? = nil,
        priority: Int? = nil
    ) async throws -> SDKBannerAdManage {
        let body = SDKBannerAdUpdateRequest(
            title: title,
            text: text,
            link: link,
            dismissible: dismissible,
            isActive: isActive,
            startsAt: startsAt,
            endsAt: endsAt,
            priority: priority
        )
        let endpoint = SDKEndpoint(
            method: .patch,
            path: "banner_ads/manage/\(id.uuidString.lowercased())/",
            body: .json(try SDKCoding.encode(body)),
            requiresAuth: true
        )
        return try await http.send(endpoint, as: SDKBannerAdManage.self)
    }

    /// Permanently delete a banner ad. `DELETE /api/banner_ads/manage/{id}/`
    ///
    /// The server answers `204 No Content`; the (empty) body is ignored.
    public func delete(id: UUID) async throws {
        let endpoint = SDKEndpoint(
            method: .delete,
            path: "banner_ads/manage/\(id.uuidString.lowercased())/",
            requiresAuth: true
        )
        try await http.sendIgnoringBody(endpoint)
    }

    // MARK: Wire payloads

    private struct SDKBannerViewerRequest: Encodable {
        let viewerId: String
    }

    private struct SDKBannerClickRequest: Encodable {
        let announcementId: UUID
    }

    private struct SDKBannerDismissRequest: Encodable {
        let announcementId: UUID
        let viewerId: String
    }

    /// Create body: `title`/`text` are non-optional; every other field relies
    /// on Swift's compiler-synthesized `Encodable` conformance, which encodes
    /// `Optional` stored properties with `encodeIfPresent` — a `nil` field is
    /// omitted from the JSON entirely, never sent as `null`.
    private struct SDKBannerAdCreateRequest: Encodable {
        let title: String
        let text: String
        let link: String?
        let dismissible: Bool?
        let isActive: Bool?
        let startsAt: Date?
        let endsAt: Date?
        let priority: Int?
    }

    /// Update (`PATCH`) body: every field is optional and, same as
    /// ``SDKBannerAdCreateRequest``, omitted from the JSON when `nil` — giving
    /// true partial-update semantics for free.
    private struct SDKBannerAdUpdateRequest: Encodable {
        let title: String?
        let text: String?
        let link: String?
        let dismissible: Bool?
        let isActive: Bool?
        let startsAt: Date?
        let endsAt: Date?
        let priority: Int?
    }
}
