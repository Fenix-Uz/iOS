import Foundation

/// Page-number pagination wrapper matching DRF's default output:
/// `{ count, next, previous, results }`. Generic over the element type so it
/// serves both order lists.
public struct SDKPaginated<Element>: Hashable, Sendable, Codable
where Element: Codable & Hashable & Sendable {
    /// Total number of items across all pages.
    public let count: Int
    /// Absolute URL of the next page, or `nil` on the last page.
    public let next: URL?
    /// Absolute URL of the previous page, or `nil` on the first page.
    public let previous: URL?
    /// Items on this page.
    public let results: [Element]

    public init(count: Int, next: URL?, previous: URL?, results: [Element]) {
        self.count = count
        self.next = next
        self.previous = previous
        self.results = results
    }

    /// `true` when another page follows.
    public var hasNextPage: Bool { next != nil }

    /// The `page` number embedded in the `next` link, if any.
    public var nextPage: Int? { SDKPaginated.pageNumber(from: next) }

    /// The `page` number embedded in the `previous` link, if any.
    public var previousPage: Int? { SDKPaginated.pageNumber(from: previous) }

    private static func pageNumber(from url: URL?) -> Int? {
        guard let url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let value = components.queryItems?.first(where: { $0.name == "page" })?.value,
              let page = Int(value) else {
            return nil
        }
        return page
    }
}
