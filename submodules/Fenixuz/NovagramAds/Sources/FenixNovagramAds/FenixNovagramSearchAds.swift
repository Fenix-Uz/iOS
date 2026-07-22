import Foundation
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext
import NovagramAds

/// A channel promoted into global search by our own ads backend
/// (`ads-api.vipads.uz`), already resolved to a Telegram peer so it can be
/// rendered and opened like any other search result.
public struct FenixNovagramPromotedChannel: Equatable {
    public let peer: EnginePeer
    public let orderId: String
    public let channelId: String

    public init(peer: EnginePeer, orderId: String, channelId: String) {
        self.peer = peer
        self.orderId = orderId
        self.channelId = channelId
    }
}

/// Novagram search ads. When the user searches globally we ask our backend for a
/// promoted channel matching the typed text; if there is one we show it at the very
/// top of the results — above Telegram's own sponsored row. No ad (the backend
/// answers HTTP 404) or any error yields `nil`, so Telegram's own results show
/// unchanged. Serving requires the `X-API-Key` (see `FenixNovagramAdsConfig`); no
/// user login is needed — the client stays anonymous otherwise.
public enum FenixNovagramSearchAds {
    // Serving needs the X-API-Key since NovagramAds 2.1.0 — without it the backend
    // returns 401 and no ad is shown.
    private static let client = SDKClient(
        configuration: SDKConfiguration(apiKey: FenixNovagramAdsConfig.apiKey)
    )

    /// Promoted channel for `query`, resolved to a Telegram peer, or `nil` if none.
    /// Emits `nil` first so the caller renders immediately, then the resolved channel
    /// once the backend answers and the peer is resolved.
    public static func promotedChannel(context: AccountContext, query: String) -> Signal<FenixNovagramPromotedChannel?, NoError> {
        let tag = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard tag.count >= 2 else {
            return .single(nil)
        }
        let viewerId = self.viewerId(context: context)

        let resolved = searchAd(tag: tag, viewerId: viewerId)
        |> mapToSignal { result -> Signal<FenixNovagramPromotedChannel?, NoError> in
            guard let result = result else {
                return .single(nil)
            }
            return context.engine.peers.resolvePeerByName(name: resolvableUsername(from: result.channelName), referrer: nil)
            |> mapToSignal { resolveResult -> Signal<FenixNovagramPromotedChannel?, NoError> in
                switch resolveResult {
                case .progress:
                    return .complete()
                case let .result(peer):
                    guard let peer = peer else {
                        return .single(nil)
                    }
                    return .single(FenixNovagramPromotedChannel(peer: peer, orderId: result.orderId.uuidString, channelId: result.channelId))
                }
            }
        }

        return .single(nil) |> then(resolved)
    }

    /// Report a tap on a promoted channel back to our backend. Fire-and-forget.
    public static func reportClick(orderId: String, context: AccountContext) {
        guard let uuid = UUID(uuidString: orderId) else {
            return
        }
        let viewerId = self.viewerId(context: context)
        Task {
            _ = try? await client.searchAds.click(orderId: uuid, viewerId: viewerId)
        }
    }

    // MARK: - channel name

    /// The backend may return the channel as a bare username ("Novagramtg") or a
    /// full link ("https://t.me/Novagramtg"); `resolvePeerByName` wants the username.
    private static func resolvableUsername(from channelName: String) -> String {
        var name = channelName.trimmingCharacters(in: .whitespacesAndNewlines)
        for prefix in ["https://t.me/", "http://t.me/", "https://telegram.me/", "t.me/", "@"] {
            if name.hasPrefix(prefix) {
                name = String(name.dropFirst(prefix.count))
                break
            }
        }
        if let cut = name.firstIndex(where: { $0 == "/" || $0 == "?" }) {
            name = String(name[..<cut])
        }
        return name
    }

    // MARK: - viewer id

    // Real Telegram user id in App Store builds; a throwaway random id in every
    // dev/test build. The backend caps each order to one view per viewer, so with a
    // real id the ad shows once and then never again — which makes it impossible to
    // test. `isAppStoreBuild` is false for `./run.sh` and `-r --prod` local builds
    // and true only for the actual App Store submission.
    private static func viewerId(context: AccountContext) -> String {
        if GlobalExperimentalSettings.isAppStoreBuild {
            return "\(context.account.peerId.id._internalGetInt64Value())"
        } else {
            return "test-\(Int64.random(in: 100_000_000 ... 999_999_999))"
        }
    }

    // MARK: - SDK bridge (async -> Signal). 404 / any error -> no ad (nil).

    private static func searchAd(tag: String, viewerId: String) -> Signal<SDKSearchResult?, NoError> {
        return Signal { subscriber in
            let task = Task {
                let result = try? await client.searchAds.search(tag: tag, viewerId: viewerId)
                if Task.isCancelled {
                    return
                }
                subscriber.putNext(result)
                subscriber.putCompletion()
            }
            return ActionDisposable {
                task.cancel()
            }
        }
    }
}
