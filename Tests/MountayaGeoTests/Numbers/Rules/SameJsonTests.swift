import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("sameJson")
struct SameJsonTests {
  @Test("two values are the same member by member, objects in any order")
  func members() throws {
    #expect(
      sameJson(
        try json(#"{"a": [1, "x", null], "b": true}"#),
        try json(#"{"b": true, "a": [1, "x", null]}"#)))
    #expect(!sameJson(try json("[1, 2]"), try json("[2, 1]")))
    #expect(!sameJson(try json(#"{"a": 1}"#), try json(#"{"a": 1, "b": 2}"#)))
    #expect(!sameJson(try json(#""1""#), try json("1")))
    #expect(!sameJson(.null, .bool(false)))
  }

  @Test("a number is compared by the same-number relation, and a string by its scalars")
  func numbersAndStrings() {
    #expect(sameJson(.number(.nan), .number(.nan)))
    #expect(!sameJson(.number(0), .number(-0.0)))
    #expect(!sameJson(.string("\u{E9}"), .string("e\u{301}")))
  }

  @Test("two values it calls the same hash alike")
  func hashing() throws {
    var first = Hasher()
    first.combine(sameJson: try json(#"{"a": [1, "x"], "b": {"c": null}}"#))
    var second = Hasher()
    second.combine(sameJson: try json(#"{"b": {"c": null}, "a": [1, "x"]}"#))
    #expect(first.finalize() == second.finalize())
    var nan = Hasher()
    nan.combine(sameJson: .number(.nan))
    var otherNan = Hasher()
    otherNan.combine(sameJson: .number(-.nan))
    #expect(nan.finalize() == otherNan.finalize())
  }

  /// The comparison reads the two with a stack of its own.
  @Test("two values nested by the thousand compare without recursion")
  func deep() {
    var left: JSONValue = 1
    var right: JSONValue = 1
    for _ in 0..<10_000 {
      left = .array([left])
      right = .array([right])
    }
    #expect(sameJson(left, right))
    // Swift releases nested arrays by recursion, so the test takes the values apart itself.
    while case .array(let elements) = left, let inner = elements.first {
      left = inner
    }
    while case .array(let elements) = right, let inner = elements.first {
      right = inner
    }
  }
}
