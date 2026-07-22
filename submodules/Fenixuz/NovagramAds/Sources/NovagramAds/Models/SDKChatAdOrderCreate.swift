import Foundation

/// Request body for creating a chat-ad order
/// (`POST /api/chat_ads/order/create/`). Only writable fields; the server
/// returns an ``SDKResponseMessage``.
///
/// Attach media by first uploading it via ``SDKChatAdsAPI/addMedia(data:filename:)``
/// and passing the returned id as ``mediaId``.
public struct SDKChatAdOrderCreate: Hashable, Sendable, Codable {
    public var orderName: String
    public var text: String
    public var link: String
    /// Comma-separated channel names, e.g. `"channel1, channel2"`.
    public var channels: String
    public var spm: SDKDecimalString
    public var budget: SDKDecimalString
    /// `-1` means unlimited shows per user. `nil` lets the server default apply.
    public var maxViewsPerUser: Int?
    public var isActive: Bool?
    public var mediaId: UUID?
    /// Which platform the ad targets. `nil` lets the server default apply.
    public var platform: SDKPlatform?

    public init(
        orderName: String,
        text: String,
        link: String,
        channels: String,
        spm: SDKDecimalString,
        budget: SDKDecimalString,
        maxViewsPerUser: Int? = nil,
        isActive: Bool? = nil,
        mediaId: UUID? = nil,
        platform: SDKPlatform? = nil
    ) {
        self.orderName = orderName
        self.text = text
        self.link = link
        self.channels = channels
        self.spm = spm
        self.budget = budget
        self.maxViewsPerUser = maxViewsPerUser
        self.isActive = isActive
        self.mediaId = mediaId
        self.platform = platform
    }
}
