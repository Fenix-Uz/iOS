import Foundation

/// A media file uploaded for a chat ad (`POST /api/chat_ads/order/add_media/`).
/// The returned ``id`` is what you pass as `mediaId` when creating the order.
public struct SDKChatAdMedia: Hashable, Sendable, Codable, Identifiable {
    public let id: UUID
    public let file: URL
    public let mediaType: SDKMediaType
    public let createdAt: Date
    public let isLinked: Bool

    public init(id: UUID, file: URL, mediaType: SDKMediaType, createdAt: Date, isLinked: Bool) {
        self.id = id
        self.file = file
        self.mediaType = mediaType
        self.createdAt = createdAt
        self.isLinked = isLinked
    }
}
