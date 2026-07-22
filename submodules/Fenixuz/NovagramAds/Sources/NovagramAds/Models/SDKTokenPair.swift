import Foundation

/// A JWT access/refresh pair returned by the login endpoint and used to persist
/// a session.
public struct SDKTokenPair: Hashable, Sendable, Codable {
    /// Short-lived bearer token sent on every authenticated request.
    public let access: String
    /// Long-lived token used to mint a new `access` token without re-login.
    public let refresh: String

    public init(access: String, refresh: String) {
        self.access = access
        self.refresh = refresh
    }
}
