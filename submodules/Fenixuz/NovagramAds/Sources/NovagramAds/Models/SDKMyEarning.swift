import Foundation

/// A confirmed channel owner's earnings row from `GET /api/partner/my/`
/// (paginated). Unlike ``SDKPublicEarning`` it exposes the amount available to
/// withdraw and the owner's revenue-share rate.
///
/// > Note: the API marks only `channel_id` and `share_rate` as required, so the
/// > remaining fields are modeled optional — the live test account owns no
/// > confirmed channels, so a real non-empty row could not be captured to prove
/// > they are always present. This keeps a valid response from failing to
/// > decode if the server omits a computed field.
public struct SDKMyEarning: Hashable, Sendable, Codable, Identifiable {
    /// Telegram channel id (`int64`) — can be negative.
    public let channelId: Int64
    /// Owner revenue-share rate (0…1), e.g. `"0.5"`. Always present.
    public let shareRate: SDKDecimalString
    public let channelName: String?
    /// Amount currently available to withdraw.
    public let available: SDKDecimalString?
    public let totalEarned: SDKDecimalString?
    public let totalImpressions: Int?
    public let claimStatus: SDKClaimStatus?
    /// When the claim was confirmed, or `nil` while still pending.
    public let claimedAt: Date?

    public var id: Int64 { channelId }

    public init(
        channelId: Int64,
        shareRate: SDKDecimalString,
        channelName: String? = nil,
        available: SDKDecimalString? = nil,
        totalEarned: SDKDecimalString? = nil,
        totalImpressions: Int? = nil,
        claimStatus: SDKClaimStatus? = nil,
        claimedAt: Date? = nil
    ) {
        self.channelId = channelId
        self.shareRate = shareRate
        self.channelName = channelName
        self.available = available
        self.totalEarned = totalEarned
        self.totalImpressions = totalImpressions
        self.claimStatus = claimStatus
        self.claimedAt = claimedAt
    }
}
