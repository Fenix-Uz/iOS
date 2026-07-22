import Foundation
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext
import NovagramAds

/// In-channel Novagram ads. Telegram gates its own sponsored messages to the
/// official api_id, so `adMessagesContext.state` is always empty on this fork.
/// Instead we fetch an ad from OUR backend (`ads-api.vipads.uz`) for the channel
/// being viewed and render it as a sponsored `Message` in the exact same slot.
/// No ad (HTTP 404) or any error yields an empty state, so the slot just stays empty.
public enum FenixNovagramChatAds {
    public typealias AdState = (interPostInterval: Int32?, messages: [Message], startDelay: Int32?, betweenDelay: Int32?)

    // Ad serving authenticates with the X-API-Key — never the user JWT (that is
    // admin-panel only) — since NovagramAds 2.1.0. No token store: impression and
    // click stats stay tied to the viewer id, not a shared account.
    private static let client = SDKClient(
        configuration: SDKConfiguration(apiKey: FenixNovagramAdsConfig.apiKey)
    )

    /// The sponsored-slot source for a channel — replaces `adMessagesContext.state`.
    public static func chatAdMessages(context: AccountContext, peerId: EnginePeer.Id) -> Signal<AdState, NoError> {
        let empty: AdState = (nil, [], nil, nil)
        // Only broadcast channels carry the sponsored slot.
        guard peerId.namespace == Namespaces.Peer.CloudChannel else {
            return .single(empty)
        }
        return context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
        |> mapToSignal { peer -> Signal<AdState, NoError> in
            guard let peer, case let .channel(channel) = peer, case .broadcast = channel.info else {
                return .single(empty)
            }
            // Which channel to ask the backend for an ad. App Store builds use the
            // channel's own username. Dev/test builds force the one channel that
            // currently has an active order ("Kunuz") so the sponsored slot is visible
            // in ANY opened channel while testing the fetch/render/click pipeline.
            // TEMPORARY — remove the else branch once real per-channel orders exist and
            // the backend matches usernames (case-insensitive).
            let channelName: String
            if GlobalExperimentalSettings.isAppStoreBuild {
                guard let addressName = channel.addressName, !addressName.isEmpty else {
                    return .single(empty)
                }
                // The backend matches channel_name case-sensitively and stores
                // usernames lowercased, while Telegram returns the canonical case
                // (e.g. "Kunuz"). Lowercase so "Kunuz"/"KUNUZ" resolve to "kunuz".
                channelName = addressName.lowercased()
            } else {
                channelName = "kunuz"
            }
            let authorPeer = peer._asPeer()
            let viewerId = self.viewerId(context: context)
            return fetchAd(channelName: channelName, viewerId: viewerId)
            |> map { ad -> AdState in
                guard let ad, let message = makeMessage(ad: ad, peerId: peerId, channelPeer: authorPeer) else {
                    return empty
                }
                return (nil, [message], nil, nil)
            }
        }
    }

    /// Report a tap on one of our sponsored messages. The opaqueId we encoded in
    /// `makeMessage` is `novagram:<orderId>`; anything else is a Telegram-origin ad
    /// we don't own, so we skip it. Fire-and-forget.
    public static func reportClick(opaqueId: Data, context: AccountContext) {
        guard let decoded = String(data: opaqueId, encoding: .utf8), decoded.hasPrefix("novagram:") else {
            return
        }
        let orderIdString = String(decoded.dropFirst("novagram:".count))
        guard let orderId = UUID(uuidString: orderIdString) else {
            return
        }
        let viewerId = self.viewerId(context: context)
        Task {
            _ = try? await client.chatAds.click(orderId: orderId, viewerId: viewerId)
        }
    }

    // MARK: - viewer id

    // Real Telegram user id in App Store builds; a throwaway random id in every
    // dev/test build (the backend caps each order to a few views per viewer, so a
    // real id would show the ad a few times then never again while testing).
    private static func viewerId(context: AccountContext) -> String {
        if GlobalExperimentalSettings.isAppStoreBuild {
            return "\(context.account.peerId.id._internalGetInt64Value())"
        } else {
            return "test-\(Int64.random(in: 100_000_000 ... 999_999_999))"
        }
    }

    // MARK: - Fetch (async -> Signal). 404 / any error -> no ad (nil).

    private static func fetchAd(channelName: String, viewerId: String) -> Signal<SDKChatAdSearch?, NoError> {
        return Signal { subscriber in
            let task = Task {
                let ad = try? await client.chatAds.search(channelName: channelName, viewerId: viewerId)
                if Task.isCancelled {
                    return
                }
                subscriber.putNext(ad)
                subscriber.putCompletion()
            }
            return ActionDisposable {
                task.cancel()
            }
        }
    }

    // MARK: - SDKChatAdSearch -> Telegram sponsored Message

    // Mirrors AdMessagesHistoryContextImpl.CachedMessage.toMessage(...) (and the
    // fakeAds path in ChatHistoryListNode) so the ad renders through Telegram's own
    // sponsored-message UI unchanged.
    private static func makeMessage(ad: SDKChatAdSearch, peerId: EnginePeer.Id, channelPeer: Peer) -> Message? {
        var attributes: [MessageAttribute] = []

        // Render the ad's media (if any) as sponsored-message media. Real sponsored
        // messages carry a TelegramMediaImage (photo) or TelegramMediaFile (video) in
        // Message.media, and the ad bubble renders exactly those two — a
        // TelegramMediaWebFile is NOT shown in the sponsored layout. The backend
        // returns a plain HTTP mediaUrl; HttpReferenceMediaResource fetches it over
        // HTTPS by URL (cloud reference not needed).
        var messageMedia: [Media] = []
        if let mediaUrl = ad.mediaUrl {
            // The backend returns media as a HOST-RELATIVE path ("/media/…"), so
            // absoluteString alone is unfetchable — prepend the API host. The
            // /media/ path is public (served via CDN, no X-API-Key needed).
            let absoluteMediaURL = mediaUrl.host != nil
                ? mediaUrl.absoluteString
                : "https://ads-api.vipads.uz" + mediaUrl.absoluteString
            let mediaIdValue = Int64(bitPattern: UInt64(truncatingIfNeeded: absoluteMediaURL.hashValue))
            // We don't know the real pixel size; a 16:9 default reserves a sane
            // bubble slot and the media just fits into it.
            let dimensions = PixelDimensions(width: 1280, height: 720)

            if ad.mediaType == "VIDEO" {
                // Video ad: a TelegramMediaFile with a .Video attribute makes the ad
                // bubble play it inline. HttpReferenceMediaResource can only download
                // the whole file (no byte-range streaming), which is fine for a short
                // ad clip — it shows a solid placeholder until the download finishes,
                // then plays (autoplay depends on the user's autoplayVideo setting;
                // otherwise tap-to-play).
                let file = TelegramMediaFile(
                    fileId: MediaId(namespace: Namespaces.Media.CloudFile, id: mediaIdValue),
                    partialReference: nil,
                    resource: HttpReferenceMediaResource(url: absoluteMediaURL, size: nil),
                    previewRepresentations: [],
                    videoThumbnails: [],
                    videoCover: nil,
                    immediateThumbnailData: nil,
                    mimeType: "video/mp4",
                    size: nil,
                    attributes: [
                        .Video(duration: 0, size: dimensions, flags: [], preloadSize: nil, coverTime: nil, videoCodec: nil),
                        .FileName(fileName: "ad.mp4")
                    ],
                    alternativeRepresentations: []
                )
                messageMedia.append(file)
            } else {
                // Image ad (default): TelegramMediaImage, the type real sponsored
                // photos use — the ad bubble renders it inline.
                let representation = TelegramMediaImageRepresentation(
                    dimensions: dimensions,
                    resource: HttpReferenceMediaResource(url: absoluteMediaURL, size: nil),
                    progressiveSizes: [],
                    immediateThumbnailData: nil
                )
                messageMedia.append(TelegramMediaImage(
                    imageId: MediaId(namespace: Namespaces.Media.CloudImage, id: mediaIdValue),
                    representations: [representation],
                    immediateThumbnailData: nil,
                    reference: nil,
                    partialReference: nil,
                    flags: []
                ))
            }
        }

        // Encode the orderId so reportClick(opaqueId:) can recover it on tap.
        let opaqueId = "novagram:\(ad.orderId.uuidString)".data(using: .utf8) ?? Data()
        attributes.append(AdMessageAttribute(
            opaqueId: opaqueId,
            messageType: .sponsored,
            url: ad.link,
            buttonText: "OPEN",
            sponsorInfo: nil,
            additionalInfo: nil,
            canReport: false,
            hasContentMedia: !messageMedia.isEmpty,
            minDisplayDuration: nil,
            maxDisplayDuration: nil
        ))

        var messagePeers = SimpleDictionary<PeerId, Peer>()
        messagePeers[channelPeer.id] = channelPeer

        let author: Peer = TelegramChannel(
            id: PeerId(namespace: Namespaces.Peer.CloudChannel, id: PeerId.Id._internalFromInt64Value(1)),
            accessHash: nil,
            title: "Reklama",
            username: nil,
            photo: [],
            creationDate: 0,
            version: 0,
            participationStatus: .left,
            info: .broadcast(TelegramChannelBroadcastInfo(flags: [])),
            flags: [],
            restrictionInfo: nil,
            adminRights: nil,
            bannedRights: nil,
            defaultBannedRights: nil,
            usernames: [],
            storiesHidden: nil,
            nameColor: .blue,
            backgroundEmojiId: nil,
            profileColor: nil,
            profileBackgroundEmojiId: nil,
            emojiStatus: nil,
            approximateBoostLevel: nil,
            subscriptionUntilDate: nil,
            verificationIconFileId: nil,
            sendPaidMessageStars: nil,
            linkedMonoforumId: nil
        )
        messagePeers[author.id] = author

        let messageHash = (ad.text.hashValue &+ 31 &* peerId.hashValue) &* 31 &+ author.id.hashValue
        let messageStableVersion = UInt32(bitPattern: Int32(truncatingIfNeeded: messageHash))

        return Message(
            stableId: 0,
            stableVersion: messageStableVersion,
            id: MessageId(peerId: peerId, namespace: Namespaces.Message.Local, id: 0),
            globallyUniqueId: nil,
            groupingKey: nil,
            groupInfo: nil,
            threadId: nil,
            timestamp: Int32.max - 1,
            flags: [.Incoming],
            tags: [],
            globalTags: [],
            localTags: [],
            customTags: [],
            forwardInfo: nil,
            author: author,
            text: ad.text,
            attributes: attributes,
            media: messageMedia,
            peers: messagePeers,
            associatedMessages: SimpleDictionary<MessageId, Message>(),
            associatedMessageIds: [],
            associatedMedia: [:],
            associatedThreadInfo: nil,
            associatedStories: [:]
        )
    }
}
