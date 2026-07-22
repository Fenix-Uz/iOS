import Foundation

/// A banner ad ready to show in a chat list
/// (`POST /api/banner_ads/active/`) — title/text/link, whether the viewer can
/// dismiss it, and when it stops showing. The backend reuses its
/// `announcements` schema for this field set. Access via
/// ``SDKBannerAdsAPI/activeBanners(viewerId:)``.
public struct SDKBannerAd: Hashable, Sendable, Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let text: String
    public let link: String
    public let dismissible: Bool
    /// When the banner stops showing. `nil` means it runs indefinitely.
    public let endsAt: Date?

    public init(
        id: UUID,
        title: String,
        text: String,
        link: String,
        dismissible: Bool,
        endsAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.link = link
        self.dismissible = dismissible
        self.endsAt = endsAt
    }
}
