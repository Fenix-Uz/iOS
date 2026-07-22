import Foundation

/// Request body for fetching a chat ad to show
/// (`POST /api/chat_ads/order/search/`).
public struct SDKAdRequest: Hashable, Sendable, Codable {
    public var channelName: String
    /// Identifier of the user viewing the ad (used for per-user show limits).
    public var viewerId: String
    /// Optional numeric channel id (`int64`), when targeting by id not name.
    public var channelId: Int64?

    public init(channelName: String, viewerId: String, channelId: Int64? = nil) {
        self.channelName = channelName
        self.viewerId = viewerId
        self.channelId = channelId
    }
}
