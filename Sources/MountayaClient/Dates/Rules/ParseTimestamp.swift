import Foundation

/// parseTimestamp returns the instant a text names where it is, whole, the one timestamp form the
/// contract carries, and nil for any other text (`transport.dates.reviver`).
///
/// It is the anchor every date the client decodes is read by, published so a rule that holds a
/// timestamp as text reads it as the wire is read, as the geo layer reads a waypoint's `date`
/// field. The form is `YYYY-MM-DDTHH:MM:SS`, an optional fraction of a second, and `Z` or an offset
/// written `+HH:MM` or `-HH:MM`, every field in range for the date it names. A day past its month's
/// last, the hour 24, a second of 60 and an offset past 23:59 name no instant, where a platform's
/// parser may carry them into a later one.
public func parseTimestamp(_ text: String) -> Date? {
  Timestamp.date(from: text)
}
