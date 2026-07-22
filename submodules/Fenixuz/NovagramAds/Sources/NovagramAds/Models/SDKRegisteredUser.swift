import Foundation

/// The account returned by `POST /api/auth/register/`. Password fields are
/// write-only and never echoed back.
public struct SDKRegisteredUser: Hashable, Sendable, Codable {
    public let username: String
    public let email: String?
    public let isAdmin: Bool

    public init(username: String, email: String? = nil, isAdmin: Bool) {
        self.username = username
        self.email = email
        self.isAdmin = isAdmin
    }
}
