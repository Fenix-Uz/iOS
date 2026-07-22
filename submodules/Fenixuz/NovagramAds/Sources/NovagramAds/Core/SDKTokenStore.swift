import Foundation
#if canImport(Security)
import Security
#endif

/// Persistence strategy for the JWT token pair. The in-memory token state lives
/// inside ``SDKAuthProvider``; a store only decides whether that state outlives
/// the process. Being a `Sendable` protocol with no Swift-side mutable state,
/// implementations are safe to hand to the auth actor.
public protocol SDKTokenStore: Sendable {
    /// Load a previously persisted pair, or `nil` if none/unavailable.
    func restore() -> SDKTokenPair?
    /// Persist the pair, or clear storage when passed `nil`.
    func persist(_ tokens: SDKTokenPair?)
}

/// Default store: tokens live only for the lifetime of the ``SDKClient``.
/// Nothing touches disk, which makes it ideal for tests and short-lived tasks.
public struct SDKEphemeralTokenStore: SDKTokenStore {
    public init() {}
    public func restore() -> SDKTokenPair? { nil }
    public func persist(_ tokens: SDKTokenPair?) {}
}

#if canImport(Security)
/// Keychain-backed store so a login survives app relaunches. Opt in by passing
/// it to ``SDKClient/init(configuration:tokenStore:sessionConfiguration:)``.
/// Tokens are stored as a generic-password item — never in `UserDefaults`.
public struct SDKKeychainTokenStore: SDKTokenStore {
    private let service: String
    private let account: String

    public init(service: String = "uz.vipads.novagramads.tokens", account: String = "default") {
        self.service = service
        self.account = account
    }

    public func restore() -> SDKTokenPair? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(SDKTokenPair.self, from: data)
    }

    public func persist(_ tokens: SDKTokenPair?) {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(base as CFDictionary)

        guard let tokens, let data = try? JSONEncoder().encode(tokens) else { return }
        var attributes = base
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }
}
#endif
