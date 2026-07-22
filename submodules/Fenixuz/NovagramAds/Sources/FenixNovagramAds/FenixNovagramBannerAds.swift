import Foundation
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext
import NovagramAds
import FenixuzProMessager

/// Neutral banner value produced by FenixNovagramAds. The GlobalControlPanelsContext
/// producer hook maps this to a `.link` ChatListNotice — keeping the dependency
/// one-directional (GlobalControlPanelsContext -> FenixNovagramAds) with no cycle.
public struct FenixBannerNotice: Equatable {
    public let id: String   // raw banner UUID string (hook prefixes it with "novagram-banner:")
    public let url: String
    public let title: String
    public let text: String
    public init(id: String, url: String, title: String, text: String) {
        self.id = id
        self.url = url
        self.title = title
        self.text = text
    }
}

/// Top-of-chat-list banner ads from OUR backend (`ads-api.vipads.uz`), rendered
/// through Telegram's own `.link` ChatListNotice slot. The notice producer in
/// GlobalControlPanelsContext asks us first: if we have a banner we return a
/// `.link` notice and it shows above everything; if we have none (empty / 404 /
/// error / ads gate off / locally dismissed) we return `nil` and Telegram's
/// existing notice chain runs unchanged.
///
/// Serving authenticates with the X-API-Key (never the user JWT — that is
/// admin-panel only); the `active/` route is read-only and not metered, so the
/// fetch is cached module-wide to avoid re-hitting the network on every
/// re-subscribe (dedup is for efficiency, not impression accounting).
public enum FenixNovagramBannerAds {
    // Same X-API-Key idiom as the chat/search ad clients (NovagramAds 2.1.0+).
    private static let client = SDKClient(
        configuration: SDKConfiguration(apiKey: FenixNovagramAdsConfig.apiKey)
    )

    // Local dismissed-set store: same UserDefaults suite the NovagramPro toggles use.
    private static let udSuite = "pro_messager"
    private static let dismissedKey = "fenix_banner_dismissed_ids"

    // MARK: - Notice producer

    /// The OURS-FIRST branch for the chat-list notice producer. Emits `nil` while
    /// the ads gate is off; otherwise the first active banner not locally dismissed,
    /// mapped to a `.link` notice. Re-emits reactively whenever `.fenixShowAdsChanged`
    /// posts (ads toggle flip OR a local dismiss), so the banner appears/disappears
    /// live without reopening the chat list.
    public static func bannerNotice(context: AccountContext) -> Signal<FenixBannerNotice?, NoError> {
        let viewerId = self.viewerId(context: context)
        // enabledSignal emits the current gate value now and re-emits on
        // .fenixShowAdsChanged — which markDismissed also posts, so a dismiss
        // re-runs the map below and filters the banner out to nil immediately.
        return FenixShowAdsGate.enabledSignal
        |> mapToSignal { enabled -> Signal<FenixBannerNotice?, NoError> in
            guard enabled else {
                return .single(nil)
            }
            return cachedActiveBanners(viewerId: viewerId)
            |> map { banners -> FenixBannerNotice? in
                guard let ad = banners.first(where: { !isDismissed(id: $0.id.uuidString) }) else {
                    return nil
                }
                return FenixBannerNotice(id: ad.id.uuidString, url: ad.link, title: ad.title, text: ad.text)
            }
        }
    }

    // MARK: - Click / dismiss

    /// Report a tap on the banner back to our backend. Fire-and-forget.
    public static func reportClick(bannerId: UUID, context: AccountContext) {
        Task {
            _ = try? await client.bannerAds.click(bannerId: bannerId)
        }
    }

    /// Dismiss the banner for this viewer: (a) tell the backend so it stays gone
    /// across reinstalls, (b) record it locally so it hides instantly even before
    /// the backend answers, (c) poke `.fenixShowAdsChanged` so `bannerNotice`
    /// re-evaluates and drops to `nil` right away.
    public static func markDismissed(bannerId: UUID, viewerId: String, context: AccountContext) {
        Task {
            _ = try? await client.bannerAds.dismiss(bannerId: bannerId, viewerId: viewerId)
        }
        addDismissed(id: bannerId.uuidString)
        NotificationCenter.default.post(name: .fenixShowAdsChanged, object: nil)
    }

    // MARK: - Local dismissed set

    /// Whether a banner id was locally dismissed by this viewer.
    public static func isDismissed(id: String) -> Bool {
        return dismissedIds().contains(id)
    }

    private static func dismissedIds() -> Set<String> {
        let ids = UserDefaults(suiteName: udSuite)?.stringArray(forKey: dismissedKey) ?? []
        return Set(ids)
    }

    private static func addDismissed(id: String) {
        var ids = dismissedIds()
        ids.insert(id)
        UserDefaults(suiteName: udSuite)?.set(Array(ids), forKey: dismissedKey)
    }

    // MARK: - viewer id

    // Real Telegram user id in App Store builds; a throwaway random id in every
    // dev/test build (the backend caps each order to a few views per viewer, so a
    // real id would show the ad a few times then never again while testing).
    public static func viewerId(context: AccountContext) -> String {
        if GlobalExperimentalSettings.isAppStoreBuild {
            return "\(context.account.peerId.id._internalGetInt64Value())"
        } else {
            return "test-\(Int64.random(in: 100_000_000 ... 999_999_999))"
        }
    }

    // MARK: - Cached fetch (async -> Signal). [] / 404 / any error -> no banners.

    // Module-wide one-shot: the first subscriber triggers the network call; every
    // later re-subscribe replays the cached list from the Promise instead of
    // hitting the network again.
    private static let bannersPromise = Promise<[SDKBannerAd]>()
    private static let fetchLock = NSLock()
    private static var didStartFetch = false

    private static func cachedActiveBanners(viewerId: String) -> Signal<[SDKBannerAd], NoError> {
        fetchLock.lock()
        if !didStartFetch {
            didStartFetch = true
            bannersPromise.set(fetchActiveBanners(viewerId: viewerId))
        }
        fetchLock.unlock()
        return bannersPromise.get()
    }

    private static func fetchActiveBanners(viewerId: String) -> Signal<[SDKBannerAd], NoError> {
        return Signal { subscriber in
            let task = Task {
                let banners = (try? await client.bannerAds.activeBanners(viewerId: viewerId)) ?? []
                if Task.isCancelled {
                    return
                }
                subscriber.putNext(banners)
                subscriber.putCompletion()
            }
            return ActionDisposable {
                task.cancel()
            }
        }
    }
}
