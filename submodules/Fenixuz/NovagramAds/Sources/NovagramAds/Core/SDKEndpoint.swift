import Foundation

/// The body payload carried by a request.
enum SDKRequestBody: Sendable {
    /// Pre-encoded JSON, sent as `application/json`.
    case json(Data)
    /// Arbitrary bytes with an explicit content type (used for multipart uploads).
    case raw(Data, contentType: String)
}

/// A fully-described API request, independent of transport. The endpoint knows
/// its verb, path (relative to the base URL, with the trailing slash Django
/// needs), query items, optional body, and whether a bearer token is required.
struct SDKEndpoint: Sendable {
    let method: SDKHTTPMethod
    let path: String
    let query: [URLQueryItem]
    let body: SDKRequestBody?
    let requiresAuth: Bool
    /// When true, attach the configured `X-API-Key` (ad-serving endpoints only).
    let sendsApiKey: Bool

    init(
        method: SDKHTTPMethod,
        path: String,
        query: [URLQueryItem] = [],
        body: SDKRequestBody? = nil,
        requiresAuth: Bool,
        sendsApiKey: Bool = false
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.body = body
        self.requiresAuth = requiresAuth
        self.sendsApiKey = sendsApiKey
    }

    /// Resolve this endpoint against a base URL into a concrete `URL`.
    func url(relativeTo baseURL: URL) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw SDKError.invalidRequest(reason: "Malformed base URL: \(baseURL.absoluteString)")
        }
        let base = components.path.hasSuffix("/") ? components.path : components.path + "/"
        components.path = base + path
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else {
            throw SDKError.invalidRequest(reason: "Could not build URL for path: \(path)")
        }
        return url
    }
}
