import Foundation

/// A single channel match from `POST /api/search_ads/order/search/`.
public struct SDKSearchResult: Hashable, Sendable, Codable {
    public let channelId: String
    public let channelName: String
    public let orderId: UUID
    /// The platform the matched channel serves ads on, when provided.
    public let platform: SDKPlatform?

    public init(channelId: String, channelName: String, orderId: UUID, platform: SDKPlatform? = nil) {
        self.channelId = channelId
        self.channelName = channelName
        self.orderId = orderId
        self.platform = platform
    }
}
