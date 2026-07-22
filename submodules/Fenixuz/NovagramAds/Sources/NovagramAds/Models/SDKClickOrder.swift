import Foundation

/// Request body for registering a click on an order. Shared by both
/// `POST /api/chat_ads/order/click/` and `POST /api/search_ads/order/click/`
/// (the two server schemas are identical).
public struct SDKClickOrder: Hashable, Sendable, Codable {
    public var orderId: UUID
    /// Identifier of the user who viewed/clicked the ad.
    public var viewerId: String

    public init(orderId: UUID, viewerId: String) {
        self.orderId = orderId
        self.viewerId = viewerId
    }
}
