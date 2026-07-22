import Foundation

/// A chat-ad order as returned by detail/list endpoints
/// (`GET /api/chat_ads/order/{id}/detail/`, `.../orders/active|all/`).
///
/// To *create* an order use ``SDKChatAdOrderCreate`` — this type carries the
/// server-computed read-only fields (views, clicks, refund, timestamps).
public struct SDKChatAdOrder: Hashable, Sendable, Codable, Identifiable {
    public let orderId: UUID
    public let userId: String
    public let orderName: String
    public let text: String
    public let link: String
    /// Comma-separated channel names the ad targets.
    public let channels: String
    public let mediaUrl: URL?
    public let spm: SDKDecimalString
    public let budget: SDKDecimalString
    public let totalViews: Int
    public let clicks: Int
    public let maxViewsPerUser: Int?
    public let shownViews: Int
    public let remainingViews: Int
    public let refundAmount: SDKDecimalString
    public let completed: Bool
    public let cancelled: Bool
    public let isActive: Bool?
    public let createdAt: Date
    /// The platform the ad runs on. Optional: omitted by older server builds.
    public let platform: SDKPlatform?

    public var id: UUID { orderId }

    public init(
        orderId: UUID,
        userId: String,
        orderName: String,
        text: String,
        link: String,
        channels: String,
        mediaUrl: URL? = nil,
        spm: SDKDecimalString,
        budget: SDKDecimalString,
        totalViews: Int,
        clicks: Int,
        maxViewsPerUser: Int? = nil,
        shownViews: Int,
        remainingViews: Int,
        refundAmount: SDKDecimalString,
        completed: Bool,
        cancelled: Bool,
        isActive: Bool? = nil,
        createdAt: Date,
        platform: SDKPlatform? = nil
    ) {
        self.orderId = orderId
        self.userId = userId
        self.orderName = orderName
        self.text = text
        self.link = link
        self.channels = channels
        self.mediaUrl = mediaUrl
        self.spm = spm
        self.budget = budget
        self.totalViews = totalViews
        self.clicks = clicks
        self.maxViewsPerUser = maxViewsPerUser
        self.shownViews = shownViews
        self.remainingViews = remainingViews
        self.refundAmount = refundAmount
        self.completed = completed
        self.cancelled = cancelled
        self.isActive = isActive
        self.createdAt = createdAt
        self.platform = platform
    }
}
