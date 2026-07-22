import Foundation

/// Request body for `POST /api/search_ads/order/create/` — creates a channel and
/// its order in one call. The server returns an ``SDKResponseMessage``.
public struct SDKCreateChannelOrder: Hashable, Sendable, Codable {
    public var channelId: String
    public var channelName: String
    public var tags: [String]
    public var orderName: String
    public var spm: SDKDecimalString
    public var budget: SDKDecimalString
    public var maxViewsPerUser: Int
    public var isActive: Bool
    /// Which platform the order targets. Defaults to `.telegram`.
    public var platform: SDKPlatform

    public init(
        channelId: String,
        channelName: String,
        orderName: String,
        spm: SDKDecimalString,
        budget: SDKDecimalString,
        tags: [String] = [],
        maxViewsPerUser: Int = 1,
        isActive: Bool = true,
        platform: SDKPlatform = .telegram
    ) {
        self.channelId = channelId
        self.channelName = channelName
        self.tags = tags
        self.orderName = orderName
        self.spm = spm
        self.budget = budget
        self.maxViewsPerUser = maxViewsPerUser
        self.isActive = isActive
        self.platform = platform
    }
}
