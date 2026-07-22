import Foundation

/// Shared query-item helpers so the paginated endpoints don't each re-derive
/// the same `page` / `page_size` construction.
enum SDKQuery {
    static func pagination(page: Int?, pageSize: Int?) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let page {
            items.append(URLQueryItem(name: "page", value: String(page)))
        }
        if let pageSize {
            items.append(URLQueryItem(name: "page_size", value: String(pageSize)))
        }
        return items
    }
}
