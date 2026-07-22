import Foundation

/// Date parsing/formatting for the API's ISO-8601 timestamps.
///
/// The backend (Django REST Framework) emits timestamps such as
/// `2026-07-11T10:52:09.357514+05:00` — full internet date-time, an explicit
/// timezone offset, and *fractional seconds*. A plain `.iso8601` strategy
/// rejects the fractional part, while a fractional-only formatter rejects
/// timestamps that omit it (e.g. `2026-07-11T12:02:07+05:00`). We therefore
/// try both, in order.
///
/// The two formatters are read-only after configuration; `ISO8601DateFormatter`
/// parsing is documented as thread-safe, so `nonisolated(unsafe)` shared
/// instances are correct under Swift 6 strict concurrency.
enum SDKDate {
    nonisolated(unsafe) private static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) private static let withoutFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Parse an API timestamp string, tolerating both fractional and
    /// non-fractional forms. Returns `nil` when neither formatter matches.
    static func date(from string: String) -> Date? {
        withFractionalSeconds.date(from: string) ?? withoutFractionalSeconds.date(from: string)
    }

    /// Format a `Date` back into the API's fractional-second ISO-8601 form.
    static func string(from date: Date) -> String {
        withFractionalSeconds.string(from: date)
    }
}
