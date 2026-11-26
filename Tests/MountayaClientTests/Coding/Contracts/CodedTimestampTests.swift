import Foundation
import Testing

@testable import MountayaClient

@Suite("CodedTimestamp")
struct CodedTimestampTests {
  @Test("a timestamp is read through the anchor and written in UTC to the millisecond")
  func anchored() throws {
    let coded = try ScriptedSender.decode(CodedTimestamp.self, from: #""2026-03-14T09:26:53Z""#)

    #expect(coded.date == Date(timeIntervalSince1970: 1_773_480_413))
    #expect(try ScriptedSender.json(coded) == #""2026-03-14T09:26:53.000Z""#)
    #expect(throws: DecodingError.self) {
      try ScriptedSender.decode(CodedTimestamp.self, from: #""2026-03-14""#)
    }
  }
}
