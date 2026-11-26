import GateSupport

/// Tolerance is how far a number may sit from the one a fixture expects, in one of the three
/// kinds `sdk/SPEC.md` section 10 defines.
struct Tolerance: Sendable, Hashable {
  enum Kind: String, Sendable {
    /// absolute accepts a distance of at most the value.
    case absolute
    /// relative accepts a distance of at most the value times the expected number.
    case relative
    /// angular accepts a distance of at most the value taken the short way round a circle of
    /// 360 degrees.
    case angular
  }

  let kind: Kind
  let value: Double

  init(kind: Kind, value: Double) {
    self.kind = kind
    self.value = value
  }

  /// Reads a fixture's `tolerance` member, or returns nil when it is not one this harness
  /// knows how to apply.
  init?(_ declared: OrderedJSON) {
    guard let name = declared["kind"]?.stringValue, let kind = Kind(rawValue: name),
      let value = declared["value"]?.numberValue, value >= 0, value.isFinite
    else {
      return nil
    }
    self.init(kind: kind, value: value)
  }

  /// accepts is true when an actual number is within the tolerance of the expected one.
  ///
  /// The relative form scales by the expected value, so an expected zero accepts only an
  /// exact zero: the contract states no absolute floor, and none is invented here. A number
  /// that is not finite is held by `Comparison.agrees(actual:expected:tolerance:)` before it
  /// reaches here, and none is accepted here.
  func accepts(actual: Double, expected: Double) -> Bool {
    switch kind {
    case .absolute:
      return abs(actual - expected) <= value
    case .relative:
      return abs(actual - expected) <= value * abs(expected)
    case .angular:
      let distance = abs(actual - expected).truncatingRemainder(dividingBy: 360)
      return min(distance, 360 - distance) <= value
    }
  }
}

/// Comparison holds an actual value to the one a fixture expects.
enum Comparison {
  /// mismatches lists every place the actual value differs from the expected one, each named
  /// by its path from the root. Numbers compare within the tolerance, or exactly where there
  /// is none; an object compares by its keys, in any order; everything else compares exactly,
  /// and `null` is never an absent key.
  static func mismatches(
    actual: OrderedJSON,
    expected: OrderedJSON,
    tolerance: Tolerance?,
    at path: String = "$"
  ) -> [String] {
    switch (actual, expected) {
    case (.number(let actualNumber), .number(let expectedNumber)):
      let accepted = agrees(actual: actualNumber, expected: expectedNumber, tolerance: tolerance)
      return accepted ? [] : ["\(path): \(describe(actual)), expected \(describe(expected))"]

    case (.array(let actualElements), .array(let expectedElements)):
      guard actualElements.count == expectedElements.count else {
        return [
          "\(path): \(actualElements.count) elements, expected \(expectedElements.count)"
        ]
      }
      return zip(actualElements, expectedElements).enumerated().flatMap { index, pair in
        mismatches(
          actual: pair.0,
          expected: pair.1,
          tolerance: tolerance,
          at: "\(path)[\(index)]"
        )
      }

    case (.object(let actualMembers), .object(let expectedMembers)):
      var found: [String] = []
      for member in expectedMembers {
        guard let value = actual[member.key] else {
          found.append("\(path).\(member.key): absent, expected \(describe(member.value))")
          continue
        }
        found += mismatches(
          actual: value,
          expected: member.value,
          tolerance: tolerance,
          at: "\(path).\(member.key)"
        )
      }
      for member in actualMembers where expected[member.key] == nil {
        found.append("\(path).\(member.key): \(describe(member.value)), expected no such key")
      }
      return found

    default:
      return actual == expected
        ? [] : ["\(path): \(describe(actual)), expected \(describe(expected))"]
    }
  }

  /// memberMismatches holds values produced in an order of their own to the array a fixture
  /// expects, as a set: each expected value is matched by one produced it does not differ from, in
  /// the order expected, and every value produced is used once. Every expected value no value
  /// matches and every value left over is listed.
  static func memberMismatches(
    actual: [OrderedJSON],
    expected: OrderedJSON,
    tolerance: Tolerance?
  ) -> [String] {
    guard let expectedMembers = expected.elements else {
      return ["$: values compared as a set, expected \(describe(expected))"]
    }
    var left = actual
    var found: [String] = []
    for member in expectedMembers {
      guard
        let match = left.firstIndex(where: {
          mismatches(actual: $0, expected: member, tolerance: tolerance).isEmpty
        })
      else {
        found.append("$: no value matches \(describe(member))")
        continue
      }
      left.remove(at: match)
    }
    found += left.map { "$: \(describe($0)), expected no such value" }
    return found
  }

  /// agrees is true where a number is the one expected: within the tolerance where the fixture
  /// states one, and exactly where it states none. A number that is not finite agrees with
  /// itself alone under any tolerance, `NaN` with `NaN` included, which no floating-point
  /// comparison says on its own.
  static func agrees(actual: Double, expected: Double, tolerance: Tolerance?) -> Bool {
    guard actual.isFinite, expected.isFinite else {
      return actual == expected || (actual.isNaN && expected.isNaN)
    }
    return tolerance?.accepts(actual: actual, expected: expected) ?? (actual == expected)
  }

  /// expectedRefusal returns the class a fixture expects a refusal to name, written as every
  /// fixture of the transport, geo and map layers writes one, `{"refused": "X"}` alone
  /// (`sdk/SPEC.md` §10). It returns nil for an expectation that is a value, `{"refused": null}`
  /// among them, which a case where nothing is refused writes.
  static func expectedRefusal(in expect: OrderedJSON) -> String? {
    guard let members = expect.members, members.count == 1 else { return nil }
    return expect["refused"]?.stringValue
  }

  private static func describe(_ value: OrderedJSON) -> String {
    let text = value.serialized().split(separator: "\n").map { $0.drop { $0 == " " } }
      .joined(separator: " ")
    return text.count > 120 ? String(text.prefix(120)) + "…" : text
  }
}
