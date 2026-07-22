import Foundation

/// A search/channel-ad order (`GET /api/search_ads/order/{id}/detail/` and the
/// search-ads list endpoints).
public struct SDKOrderDetail: Hashable, Sendable, Codable, Identifiable {
    public let orderId: UUID
    public let channelId: String
    public let channelName: String
    public let orderName: String
    public let tags: [String]
    /// Spend per mille — cost per 1000 impressions.
    public let spm: SDKDecimalString
    public let budget: SDKDecimalString
    public let totalViews: Int
    public let shownViews: Int
    public let remainingViews: Int
    public let clicks: Int
    public let completed: Bool
    public let cancelled: Bool
    public let isActive: Bool
    public let refundAmount: SDKDecimalString
    public let maxViewsPerUser: Int
    public let createdAt: Date
    public let updatedAt: Date
    /// The platform the ad runs on. Optional defensively (the server's rollout
    /// on read endpoints is not yet confirmable against a live order).
    public let platform: SDKPlatform?

    public var id: UUID { orderId }

    public init(
        orderId: UUID,
        channelId: String,
        channelName: String,
        orderName: String,
        tags: [String],
        spm: SDKDecimalString,
        budget: SDKDecimalString,
        totalViews: Int,
        shownViews: Int,
        remainingViews: Int,
        clicks: Int,
        completed: Bool,
        cancelled: Bool,
        isActive: Bool,
        refundAmount: SDKDecimalString,
        maxViewsPerUser: Int,
        createdAt: Date,
        updatedAt: Date,
        platform: SDKPlatform? = nil
    ) {
        self.orderId = orderId
        self.channelId = channelId
        self.channelName = channelName
        self.orderName = orderName
        self.tags = tags
        self.spm = spm
        self.budget = budget
        self.totalViews = totalViews
        self.shownViews = shownViews
        self.remainingViews = remainingViews
        self.clicks = clicks
        self.completed = completed
        self.cancelled = cancelled
        self.isActive = isActive
        self.refundAmount = refundAmount
        self.maxViewsPerUser = maxViewsPerUser
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.platform = platform
    }
}
