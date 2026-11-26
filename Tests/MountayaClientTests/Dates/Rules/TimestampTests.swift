import Foundation
import Testing

@testable import MountayaClient

@Suite("Timestamp")
struct TimestampTests {
  /// 2026-03-14T09:26:53Z.
  private static let instant = Date(timeIntervalSince1970: 1_773_480_413)

  @Test("a full timestamp with a zone is an instant, in every zone spelling")
  func readsTimestamps() {
    #expect(Timestamp.date(from: "2026-03-14T09:26:53Z") == Self.instant)
    #expect(Timestamp.date(from: "2026-03-14T09:26:53.000Z") == Self.instant)
    #expect(Timestamp.date(from: "2026-03-14T10:26:53+01:00") == Self.instant)
    #expect(Timestamp.date(from: "2026-03-14T04:56:53-04:30") == Self.instant)
    #expect(Timestamp.date(from: "2026-03-14T09:26:53-00:00") == Self.instant)
  }

  @Test("every offset the grammar writes is read, past the 18 hours some parsers stop at")
  func readsEveryOffset() {
    #expect(Timestamp.date(from: "2026-03-15T09:25:53+23:59") == Self.instant)
    #expect(Timestamp.date(from: "2026-03-13T09:27:53-23:59") == Self.instant)
  }

  @Test("a fraction of a second is kept, whatever its length")
  func readsFractions() throws {
    let date = try #require(Timestamp.date(from: "2026-03-14T09:26:53.25Z"))

    #expect(date.timeIntervalSince(Self.instant) == 0.25)
    #expect(Timestamp.date(from: "2026-03-14T09:26:53.123456789Z") != nil)
    #expect(Timestamp.date(from: "2026-03-14T09:26:53.123456789987Z") != nil)
  }

  @Test("a fraction keeps its microseconds, and the digits past them are dropped, never rounded")
  func truncatesFractions() throws {
    let micro = try #require(Timestamp.date(from: "2026-03-14T09:26:53.1234567Z"))
    let nines = try #require(Timestamp.date(from: "2026-03-14T09:26:53.999999999Z"))
    let short = try #require(Timestamp.date(from: "2026-03-14T09:26:53.5Z"))

    #expect((micro.timeIntervalSince1970 * 1_000_000).rounded() == 1_773_480_413_123_456)
    #expect((nines.timeIntervalSince1970 * 1_000_000).rounded() == 1_773_480_413_999_999)
    #expect(short.timeIntervalSince(Self.instant) == 0.5)
  }

  @Test("an instant is written to the millisecond it holds, the digits past it dropped")
  func writesTruncated() throws {
    let nines = try #require(Timestamp.date(from: "2026-03-14T09:26:53.999999999Z"))
    let six = try #require(Timestamp.date(from: "2026-03-14T09:26:53.123999Z"))
    let exact = try #require(Timestamp.date(from: "2026-03-14T09:26:53.123000Z"))

    #expect(Timestamp.string(from: nines) == "2026-03-14T09:26:53.999Z")
    #expect(Timestamp.string(from: six) == "2026-03-14T09:26:53.123Z")
    #expect(Timestamp.string(from: exact) == "2026-03-14T09:26:53.123Z")
    #expect(
      Timestamp.string(from: Self.instant.addingTimeInterval(0.000_999))
        == "2026-03-14T09:26:53.000Z"
    )
    #expect(
      Timestamp.string(from: Date(timeIntervalSince1970: -0.0005)) == "1969-12-31T23:59:59.999Z")
  }

  @Test("anything less than a whole timestamp stays a string")
  func refusesTheRest() {
    for text in [
      "2026-03-14",
      "2026-03-14T09:26:53",
      "2026-03-14T09:26:53.000Z looks like a date",
      "on 2026-03-14T09:26:53Z",
      "2026-03-14t09:26:53Z",
      "2026-03-14T09:26:53z",
      "2026-03-14 09:26:53Z",
      "2026-03-14T09:26:53+0100",
      "2026-03-14T09:26:53+01",
      "2026-03-14T09:26:53.Z",
      "2026-03-14T09:26Z",
      "26-03-14T09:26:53Z",
      "+2026-03-14T09:26:53Z",
      "2026-13-14T09:26:53Z",
      "2026-02-29T09:26:53Z",
      "2026-03-14T24:00:00Z",
      "2026-03-14T09:60:00Z",
      "2026-03-14T09:26:60Z",
      "2026-03-14T09:26:53+24:00",
      "2026-03-14T09:26:53+01:60",
      "itin_1",
      "",
    ] {
      #expect(Timestamp.date(from: text) == nil, "\(text)")
    }
  }

  @Test("an instant is written in UTC, to the millisecond")
  func writesTimestamps() {
    #expect(Timestamp.string(from: Self.instant) == "2026-03-14T09:26:53.000Z")
    #expect(
      Timestamp.string(from: Self.instant.addingTimeInterval(0.1234)) == "2026-03-14T09:26:53.123Z")
    #expect(Timestamp.string(from: Date(timeIntervalSince1970: 0)) == "1970-01-01T00:00:00.000Z")
    #expect(
      Timestamp.string(from: Date(timeIntervalSince1970: -0.001)) == "1969-12-31T23:59:59.999Z")
  }

  @Test("an instant a message names is written in UTC, to the second, the digits past it dropped")
  func writesSeconds() {
    #expect(Timestamp.secondString(from: Self.instant) == "2026-03-14T09:26:53Z")
    #expect(
      Timestamp.secondString(from: Self.instant.addingTimeInterval(0.999)) == "2026-03-14T09:26:53Z"
    )
    #expect(
      Timestamp.secondString(from: Date(timeIntervalSince1970: -0.001)) == "1969-12-31T23:59:59Z")
  }

  @Test("an instant past 2038 is read and written whole")
  func past2038() throws {
    let date = try #require(Timestamp.date(from: "2100-01-01T00:00:00Z"))

    #expect(date.timeIntervalSince1970 == 4_102_444_800)
    #expect(Timestamp.string(from: date) == "2100-01-01T00:00:00.000Z")
  }
}
