import Testing

@testable import MountayaClient

@Suite("JSONValue")
struct JSONValueTests {
  @Test("every JSON shape reads as itself and is written back")
  func roundTrip() throws {
    let text = #"{"a":null,"b":true,"c":1.5,"d":"x","e":[1,"y"],"f":{"g":false}}"#
    let value = try ScriptedSender.decode(JSONValue.self, from: text)

    #expect(
      value == ["a": nil, "b": true, "c": 1.5, "d": "x", "e": [1, "y"], "f": ["g": false]]
    )
    #expect(try ScriptedSender.json(value) == text)
  }

  @Test("a number is never read as a boolean")
  func numbersStayNumbers() throws {
    #expect(try ScriptedSender.decode(JSONValue.self, from: "1") == .number(1))
    #expect(try ScriptedSender.decode(JSONValue.self, from: "true") == .bool(true))
  }
}
