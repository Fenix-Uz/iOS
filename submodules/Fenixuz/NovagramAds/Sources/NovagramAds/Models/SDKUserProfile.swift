import Foundation

/// The authenticated user's profile (`GET /api/auth/profile/`).
public struct SDKUserProfile: Hashable, Sendable, Codable, Identifiable {
    public let userId: UUID
    public let username: String
    public let email: String?
    public let firstName: String?
    public let lastName: String?
    public let dateJoined: Date?
    public let isAdmin: Bool?

    /// `Identifiable` conformance keyed on the stable user id.
    public var id: UUID { userId }

    public init(
        userId: UUID,
        username: String,
        email: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        dateJoined: Date? = nil,
        isAdmin: Bool? = nil
    ) {
        self.userId = userId
        self.username = username
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.dateJoined = dateJoined
        self.isAdmin = isAdmin
    }
}
