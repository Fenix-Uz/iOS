import Foundation

/// Immutable configuration for an ``SDKClient``.
///
/// The default base URL points at the production API over **HTTPS**. The host
/// answers plain HTTP with a `301` redirect to HTTPS, and following that
/// redirect would strip the body from `POST` logins — so HTTPS is the correct
/// default even though the docs quote an `http://` address. Override
/// `baseURL` at init time for staging or a self-hosted instance.
public struct SDKConfiguration: Sendable {
    /// Root of the API, including the trailing `/api/`. A trailing slash is
    /// enforced so endpoint paths append cleanly (Django requires it).
    public let baseURL: URL

    /// Per-request timeout in seconds.
    public let timeout: TimeInterval

    /// Extra headers merged into every request (e.g. an app identifier).
    public let extraHeaders: [String: String]

    /// Retry behaviour for idempotent requests.
    public let retryPolicy: SDKRetryPolicy

    /// Server-to-server ad-serving key, sent as `X-API-Key` on the show/click
    /// endpoints (`chatAds.search`/`click`, `searchAds.search`/`click`). Those
    /// endpoints require it *in addition* to a bearer token.
    ///
    /// - Warning: this is a **server-side secret**. Inject it from secure backend
    ///   configuration — never embed it in a shipped mobile/desktop client. Leave
    ///   it `nil` in advertiser apps, which never call those endpoints.
    public let apiKey: String?

    /// The production API base URL.
    public static let defaultBaseURL = URL(string: "https://ads-api.vipads.uz/api/")!

    public init(
        baseURL: URL = SDKConfiguration.defaultBaseURL,
        timeout: TimeInterval = 30,
        extraHeaders: [String: String] = [:],
        retryPolicy: SDKRetryPolicy = .default,
        apiKey: String? = nil
    ) {
        self.baseURL = SDKConfiguration.normalized(baseURL)
        self.timeout = timeout
        self.extraHeaders = extraHeaders
        self.retryPolicy = retryPolicy
        self.apiKey = apiKey
    }

    /// Convenience initializer from a string, throwing ``SDKError/invalidRequest(reason:)``
    /// when the value is not a valid absolute URL.
    public init(
        baseURLString: String,
        timeout: TimeInterval = 30,
        extraHeaders: [String: String] = [:],
        retryPolicy: SDKRetryPolicy = .default,
        apiKey: String? = nil
    ) throws {
        guard let url = URL(string: baseURLString), url.scheme != nil, url.host != nil else {
            throw SDKError.invalidRequest(reason: "Invalid base URL string: \(baseURLString)")
        }
        self.init(baseURL: url, timeout: timeout, extraHeaders: extraHeaders, retryPolicy: retryPolicy, apiKey: apiKey)
    }

    /// Guarantee a single trailing slash so relative paths resolve predictably.
    private static func normalized(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        if !components.path.hasSuffix("/") {
            components.path += "/"
        }
        return components.url ?? url
    }
}
