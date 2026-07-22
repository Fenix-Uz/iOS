import Foundation

/// HTTP verbs used by the NovagramAds API surface.
///
/// Prefixed with `SDK` so it never collides with types from `Foundation`,
/// `SwiftUI`, `UIKit`, or a host app's own networking layer.
public enum SDKHTTPMethod: String, Hashable, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"

    /// Idempotent methods are safe to retry automatically on transport failures.
    var isIdempotent: Bool {
        switch self {
        case .get, .put, .delete:
            return true
        case .post, .patch:
            return false
        }
    }
}
