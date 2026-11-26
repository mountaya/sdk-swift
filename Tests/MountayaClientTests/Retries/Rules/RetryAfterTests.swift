import Foundation
import Testing

@testable import MountayaClient

@Suite("RetryAfter")
struct RetryAfterTests {
  /// 2027-01-15T08:00:00Z.
  private static let now = Date(timeIntervalSince1970: 1_800_000_000)

  private static func delay(_ header: String) -> Duration? {
    RetryAfter.delay(header: header, now: now)
  }

  @Test("a delay in whole seconds is read as written")
  func seconds() {
    #expect(Self.delay("30") == .seconds(30))
    #expect(Self.delay("0") == .zero)
    #expect(Self.delay(" 30\t") == .seconds(30))
  }

  @Test("anything that is not whole seconds or an HTTP date is ignored")
  func ignored() {
    for header in [
      "-5", "+5", "1.5", "", " ", "30s", "not-a-number", "99999999999999999999999",
    ] {
      #expect(Self.delay(header) == nil, "\(header)")
    }
  }

  @Test("an HTTP date is a wait until it, and one already past is no wait at all")
  func httpDate() {
    #expect(Self.delay("Fri, 15 Jan 2027 08:01:00 GMT") == .seconds(60))
    #expect(Self.delay("Fri, 15 Jan 2027 08:00:00 GMT") == .zero)
    #expect(Self.delay("Thu, 14 Jan 2027 08:00:00 GMT") == .zero)
    #expect(Self.delay("Sat, 16 Jan 2027 08:00:00 GMT") == .seconds(86_400))
  }

  @Test("an HTTP date's distance is rounded up to the whole second, so no wait ends before it")
  func httpDateRoundsUp() {
    let early = Date(timeIntervalSince1970: 1_800_000_000.3)
    #expect(
      RetryAfter.delay(header: "Fri, 15 Jan 2027 08:01:00 GMT", now: early) == .seconds(60),
      "59.7 s ahead")
    #expect(RetryAfter.delay(header: "Fri, 15 Jan 2027 08:00:00 GMT", now: early) == .zero)
    #expect(
      RetryAfter.delay(
        header: "Fri, 15 Jan 2027 08:00:01 GMT", now: Date(timeIntervalSince1970: 1_800_000_000.999)
      ) == .seconds(1))
  }

  @Test("the two obsolete date formats are read too")
  func obsoleteDates() {
    #expect(Self.delay("Friday, 15-Jan-27 08:01:00 GMT") == .seconds(60))
    #expect(Self.delay("Fri Jan 15 08:01:00 2027") == .seconds(60))
    #expect(Self.delay("Sat Jan  16 08:00:00 2027") == nil)
    #expect(Self.delay("Sun Jan 17 08:00:00 2027") == .seconds(2 * 86_400))
    #expect(
      RetryAfter.delay(
        header: "Sun Nov  6 08:49:37 1994", now: Date(timeIntervalSince1970: 784_111_767))
        == .seconds(10))
  }

  @Test("a two-digit year is the one no more than fifty years ahead")
  func twoDigitYear() {
    // Fifty years from 2027-01-15 hold thirteen leap days, 2028 to 2076.
    #expect(Self.delay("Friday, 15-Jan-77 08:00:00 GMT") == .seconds((50 * 365 + 13) * 86_400))
    // 2078 would be more than fifty years ahead, so the year is 1978, which is past.
    #expect(Self.delay("Sunday, 15-Jan-78 08:00:00 GMT") == .zero)
  }

  @Test("a leap day and a leap second are dates")
  func leapDayAndSecond() {
    // From 2027-01-15T08:00Z: sixteen hours to midnight, then 409 days to 29 February 2028.
    #expect(Self.delay("Tue, 29 Feb 2028 00:00:00 GMT") == .seconds(409 * 86_400 + 16 * 3600))
    #expect(Self.delay("Fri, 15 Jan 2027 08:00:60 GMT") == .seconds(60))
  }

  @Test("each date format is read strictly, and nothing looser passes as one")
  func strictDate() {
    for header in [
      "fri, 15 Jan 2027 08:01:00 GMT",
      "Fri, 15 jan 2027 08:01:00 GMT",
      "Fri, 15 Jan 2027 08:01:00 UTC",
      "Fri, 15 Jan 2027 08:01:00 +0000",
      "Fri, 5 Jan 2027 08:01:00 GMT",
      "Fri, 15 Jan 27 08:01:00 GMT",
      "Fri, 30 Feb 2027 08:01:00 GMT",
      "Fri, 15 Jan 2027 24:00:00 GMT",
      "Fri, 15 Jan 2027 08:60:00 GMT",
      "Fri, 15 Jan 2027 08:00:61 GMT",
      "Fri,  15 Jan 2027 08:01:00 GMT",
      "Fri,15 Jan 2027 08:01:00 GMT",
      "Fri, 15-Jan-27 08:01:00 GMT",
      "Friday, 15-Jan-2027 08:01:00 GMT",
      "Friday, 15 Jan 2027 08:01:00 GMT",
      "Fri Jan 15 08:01:00 27",
      "Fri Jan 15 08:01:00 2027 GMT",
      "2027-01-15T08:01:00Z",
    ] {
      #expect(Self.delay(header) == nil, "\(header)")
    }
  }
}
