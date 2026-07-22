import Foundation

/// The ad to display, returned by `POST /api/chat_ads/order/search/`. A
/// flattened, viewer-facing view of an order (media is a plain URL).
public struct SDKChatAdSearch: Hashable, Sendable, Codable, Identifiable {
    public let orderId: UUID
    public let orderName: String
    public let text: String
    public let link: String
    public let mediaUrl: URL?
    /// Raw media type string as sent by the server (`"IMAGE"`/`"VIDEO"`/`nil`).
    public let mediaType: String?
    public let totalViews: Int
    public let clicks: Int
    public let shownViews: Int
    public let remainingViews: Int
    /// The platform the ad runs on, when provided by the server.
    public let platform: SDKPlatform?

    public var id: UUID { orderId }

    public init(
        orderId: UUID,
        orderName: String,
        text: String,
        link: String,
        mediaUrl: URL? = nil,
        mediaType: String? = nil,
        totalViews: Int,
        clicks: Int,
        shownViews: Int,
        remainingViews: Int,
        platform: SDKPlatform? = nil
    ) {
        self.orderId = orderId
        self.orderName = orderName
        self.text = text
        self.link = link
        self.mediaUrl = mediaUrl
        self.mediaType = mediaType
        self.totalViews = totalViews
        self.clicks = clicks
        self.shownViews = shownViews
        self.remainingViews = remainingViews
        self.platform = platform
    }
}
