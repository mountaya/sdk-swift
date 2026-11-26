import Foundation
import Testing

@testable import MountayaClient

@Suite("WireCoded")
struct WireCodedTests {
  @Test("a collection of timestamps travels as a collection of their wire forms")
  func collections() throws {
    let dates = [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 1)]
    let map: [String: Date?] = ["a": Date(timeIntervalSince1970: 2), "b": nil]

    #expect([Date](wire: dates.wire) == dates)
    #expect(
      try ScriptedSender.json(dates.wire)
        == #"["1970-01-01T00:00:00.000Z","1970-01-01T00:00:01.000Z"]"#)
    #expect([String: Date?](wire: map.wire) == map)
    #expect(try ScriptedSender.json(map.wire) == #"{"a":"1970-01-01T00:00:02.000Z","b":null}"#)
  }
}
