import Foundation

/// Request body for activating/deactivating an order. Shared by both
/// `POST /api/chat_ads/order/change_status/` and
/// `POST /api/search_ads/order/change_status/`.
public struct SDKOrderActivation: Hashable, Sendable, Codable {
    public var orderId: UUID
    public var isActive: Bool

    public init(orderId: UUID, isActive: Bool) {
        self.orderId = orderId
        self.isActive = isActive
    }
}
