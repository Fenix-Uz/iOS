import Foundation

/// Entry point to the NovagramAds API.
///
/// ```swift
/// import NovagramAds
///
/// let client = SDKClient()                                   // production, HTTPS
/// _ = try await client.auth.login(username: "test", password: "simple1234")
/// let balance = try await client.balance.current()
/// let orders  = try await client.searchAds.allOrders(page: 1)
/// ```
///
/// Point it elsewhere at init time:
/// ```swift
/// let staging = try SDKConfiguration(baseURLString: "https://staging.example.com/api/")
/// let client  = SDKClient(configuration: staging, tokenStore: SDKKeychainTokenStore())
/// ```
///
/// The type is a `Sendable` value: the only mutable state (the token pair) is
/// isolated inside ``SDKAuthProvider``, so a single client is safe to share
/// across tasks and actors.
public struct SDKClient: Sendable {
    /// Authentication: login, register, refresh, verify, profile, logout.
    public let auth: SDKAuthAPI
    /// The current user's balance.
    public let balance: SDKBalanceAPI
    /// In-chat advertising orders and media.
    public let chatAds: SDKChatAdsAPI
    /// Search/channel advertising orders.
    public let searchAds: SDKSearchAdsAPI
    /// Channel-owner partner program: claim channels, view earnings, withdraw.
    public let partner: SDKPartnerAPI
    public let bannerAds: SDKBannerAdsAPI

    private let authProvider: SDKAuthProvider

    /// - Parameters:
    ///   - configuration: Base URL, timeout, headers, retry policy. Defaults to
    ///     the production API over HTTPS.
    ///   - tokenStore: Where tokens are persisted. Defaults to in-memory
    ///     (session only); pass ``SDKKeychainTokenStore`` to survive relaunches.
    ///   - sessionConfiguration: Underlying `URLSession` configuration. Inject a
    ///     custom one (e.g. with a mock `URLProtocol`) for testing.
    public init(
        configuration: SDKConfiguration = SDKConfiguration(),
        tokenStore: SDKTokenStore = SDKEphemeralTokenStore(),
        sessionConfiguration: URLSessionConfiguration = .default
    ) {
        sessionConfiguration.timeoutIntervalForRequest = configuration.timeout
        let session = URLSession(configuration: sessionConfiguration)
        let executor = SDKRequestExecutor(configuration: configuration, session: session)
        let authProvider = SDKAuthProvider(executor: executor, store: tokenStore)
        let http = SDKHTTPClient(
            executor: executor,
            authProvider: authProvider,
            retryPolicy: configuration.retryPolicy
        )

        self.authProvider = authProvider
        self.auth = SDKAuthAPI(http: http, authProvider: authProvider)
        self.balance = SDKBalanceAPI(http: http)
        self.chatAds = SDKChatAdsAPI(http: http)
        self.searchAds = SDKSearchAdsAPI(http: http)
        self.partner = SDKPartnerAPI(http: http)
        self.bannerAds = SDKBannerAdsAPI(http: http)
    }

    // MARK: Session helpers

    /// Whether the client currently holds a token pair (not verified server-side).
    public var isAuthenticated: Bool {
        get async { await authProvider.isAuthenticated }
    }

    /// The current token pair, if logged in.
    public func currentTokens() async -> SDKTokenPair? {
        await authProvider.currentTokens
    }

    /// Inject tokens obtained elsewhere (e.g. restored from your own storage).
    public func setTokens(_ tokens: SDKTokenPair) async {
        await authProvider.setTokens(tokens)
    }

    /// Clear the session and any persisted tokens.
    public func logout() async {
        await authProvider.logout()
    }
}

/// Discoverability alias — `NovagramAdsClient` and ``SDKClient`` are the same type.
public typealias NovagramAdsClient = SDKClient
