import Foundation
import MountayaClient
import Testing

@Suite("parseTimestamp")
struct ParseTimestampTests {
  /// 2026-03-14T09:26:53Z.
  private static let instant = Date(timeIntervalSince1970: 1_773_480_413)

  @Test("a full timestamp with a zone is the instant the anchor reads, in every zone spelling")
  func readsTimestamps() {
    #expect(parseTimestamp("2026-03-14T09:26:53Z") == Self.instant)
    #expect(parseTimestamp("2026-03-14T09:26:53.250Z") == Self.instant.addingTimeInterval(0.25))
    #expect(parseTimestamp("2026-03-14T10:26:53+01:00") == Self.instant)
    #expect(parseTimestamp("2026-03-14T09:26:53-00:00") == Self.instant)
    #expect(parseTimestamp("2026-03-15T09:25:53+23:59") == Self.instant)
  }

  @Test("a text that names no real instant is none, never a later instant")
  func refusesTheRest() {
    for text in [
      "2024-02-30T10:00:00Z",
      "2024-13-01T10:00:00Z",
      "2024-03-01T24:00:00Z",
      "2024-03-01T10:00:60Z",
      "2024-03-01T10:61:00Z",
      "2024-03-01T10:00:00+25:00",
      "2024-03-01T10:00:00+0100",
      "2024-03-01T10:00:00Z ",
      "2024-03-01",
      "soon",
    ] {
      #expect(parseTimestamp(text) == nil, "\(text)")
    }
  }
}
