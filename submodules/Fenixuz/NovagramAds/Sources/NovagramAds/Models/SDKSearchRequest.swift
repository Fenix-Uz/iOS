import Foundation

/// Request body for `POST /api/search_ads/order/search/` — find a channel by tag.
public struct SDKSearchRequest: Hashable, Sendable, Codable {
    public var tag: String
    /// Identifier of the user performing the search (used for per-user show limits).
    public var viewerId: String

    public init(tag: String, viewerId: String) {
        self.tag = tag
        self.viewerId = viewerId
    }
}
