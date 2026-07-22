import Foundation

/// The admin/manage view of a banner ad (`banner_ads/manage/…`) — everything
/// ``SDKBannerAd`` has, plus scheduling, priority, and analytics fields only
/// an admin dashboard needs. Access via ``SDKBannerAdsAPI``'s
/// `manageList`/`create`/`detail`/`update`.
public struct SDKBannerAdManage: Hashable, Sendable, Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let text: String
    public let link: String
    public let dismissible: Bool
    public let isActive: Bool
    public let startsAt: Date
    /// When the banner stops showing. `nil` means it runs indefinitely.
    public let endsAt: Date?
    /// Higher shows first when multiple banners are eligible at once.
    public let priority: Int
    public let clicks: Int
    public let dismissalsCount: Int
    /// Username of the admin who created it. `nil` when the server has none on record.
    public let createdBy: String?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID,
        title: String,
        text: String,
        link: String,
        dismissible: Bool,
        isActive: Bool,
        startsAt: Date,
        endsAt: Date? = nil,
        priority: Int,
        clicks: Int,
        dismissalsCount: Int,
        createdBy: String? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.link = link
        self.dismissible = dismissible
        self.isActive = isActive
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.priority = priority
        self.clicks = clicks
        self.dismissalsCount = dismissalsCount
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
