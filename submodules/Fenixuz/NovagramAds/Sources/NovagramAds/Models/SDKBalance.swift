import Foundation

/// The current user's wallet balance (`GET /api/balance/`).
public struct SDKBalance: Hashable, Sendable, Codable {
    public let username: String
    /// Balance amount as a precise decimal (the API sends it as `"60.00"`).
    public let amount: SDKDecimalString
    public let userId: String

    public init(username: String, amount: SDKDecimalString, userId: String) {
        self.username = username
        self.amount = amount
        self.userId = userId
    }
}
