import Foundation

/// Public "showcase" earnings for a channel, from
/// `GET /api/partner/earnings/?channel_id=<id>` — how much a channel has already
/// earned from paid impressions, with no withdrawable amount. A teaser for
/// channel owners who have not yet claimed their channel.
///
/// > Important: the endpoint **requires** a numeric `channel_id` query
/// > parameter. This is verified against the live API but missing from the
/// > published OpenAPI spec, so always call it via
/// > ``SDKPartnerAPI/earnings(channelId:)``.
public struct SDKPublicEarning: Hashable, Sendable, Codable, Identifiable {
    /// Telegram channel id (`int64`) — can be negative, e.g. `-1001001766948`.
    public let channelId: Int64
    public let channelName: String
    public let totalEarned: SDKDecimalString
    public let totalImpressions: Int
    /// `true` once an owner has claimed this channel.
    public let isClaimed: Bool

    public var id: Int64 { channelId }

    public init(
        channelId: Int64,
        channelName: String,
        totalEarned: SDKDecimalString,
        totalImpressions: Int,
        isClaimed: Bool
    ) {
        self.channelId = channelId
        self.channelName = channelName
        self.totalEarned = totalEarned
        self.totalImpressions = totalImpressions
        self.isClaimed = isClaimed
    }
}
