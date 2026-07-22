import Foundation

/// The `{ "message": … }` envelope returned by create/cancel/status/click
/// endpoints on both the chat-ads and search-ads surfaces. The two identical
/// server schemas (`ResponsesMessage` / `ChatAdResponsesMessage`) are unified
/// here into one type.
public struct SDKResponseMessage: Hashable, Sendable, Codable {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}
