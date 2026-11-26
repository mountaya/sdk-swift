import Foundation

/// WallClock is what the client reads the current instant from: the instant a `Retry-After`
/// date, a spent monthly allowance's renewal and an event stream's token expiry are read against,
/// and the one a session token's refresh is scheduled from.
///
/// A client and a session engine given none read the platform's. Nothing outside `Seams/` reads
/// the wall clock itself, so every rule that depends on the time takes one of these, and a
/// conformance stands in for the platform in a test, so that a date and a schedule are
/// reproducible.
public protocol WallClock: Sendable {
  /// now is the current instant, read afresh at every call and never cached.
  var now: Date { get }
}
