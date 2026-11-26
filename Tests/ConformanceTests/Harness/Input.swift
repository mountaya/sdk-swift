import GateSupport

/// The readers a runner takes a case's input apart with. Each throws, naming the key, where the
/// input is not the shape the runner was written for: a case read wrong is a case unproven, and
/// a default substituted for it would pass the runner over a rule nobody ran.
extension OrderedJSON {
  /// Returns the string under a key.
  func string(at key: String) throws(FixtureError) -> String {
    guard let value = self[key]?.stringValue else { throw mistyped(key, expected: "a string") }
    return value
  }

  /// Returns the string under a key, or nil where the key is absent or `null`.
  func optionalString(at key: String) throws(FixtureError) -> String? {
    guard let value = self[key], !value.isNull else { return nil }
    guard let text = value.stringValue else { throw mistyped(key, expected: "a string or null") }
    return text
  }

  /// Returns the number under a key.
  func number(at key: String) throws(FixtureError) -> Double {
    guard let value = self[key]?.numberValue else { throw mistyped(key, expected: "a number") }
    return value
  }

  /// Returns the number under a key, or nil where the key is absent or `null`.
  func optionalNumber(at key: String) throws(FixtureError) -> Double? {
    guard let value = self[key], !value.isNull else { return nil }
    guard let number = value.numberValue else { throw mistyped(key, expected: "a number or null") }
    return number
  }

  /// Returns the whole number under a key.
  func integer(at key: String) throws(FixtureError) -> Int {
    guard let value = Int(exactly: try number(at: key)) else {
      throw mistyped(key, expected: "a whole number")
    }
    return value
  }

  /// Returns the whole number under a key, or nil where the key is absent or `null`.
  func optionalInteger(at key: String) throws(FixtureError) -> Int? {
    guard let number = try optionalNumber(at: key) else { return nil }
    guard let value = Int(exactly: number) else {
      throw mistyped(key, expected: "a whole number or null")
    }
    return value
  }

  /// Returns the boolean under a key, an absent key being false: a fixture leaves out a flag
  /// it does not set.
  func flag(at key: String) throws(FixtureError) -> Bool {
    guard let value = self[key], !value.isNull else { return false }
    guard let flag = value.boolValue else { throw mistyped(key, expected: "a boolean") }
    return flag
  }

  /// Returns the array under a key.
  func array(at key: String) throws(FixtureError) -> [OrderedJSON] {
    guard let value = self[key]?.elements else { throw mistyped(key, expected: "an array") }
    return value
  }

  /// Returns the numbers of the array under a key, a position such as `[longitude, latitude]` or
  /// the edges of a box, kept as short as the fixture writes it, so a rule meets a position that
  /// names no place exactly as the fixture states it.
  func numbers(at key: String) throws(FixtureError) -> [Double] {
    guard let value = self[key] else { throw mistyped(key, expected: "an array of numbers") }
    return try value.numberList(naming: key)
  }

  /// Returns the numbers this value holds, which must be an array of numbers and nothing else;
  /// `what` names it in the sentence a failure throws.
  func numberList(naming what: String) throws(FixtureError) -> [Double] {
    guard let elements else {
      throw FixtureError(description: "`\(what)` is not an array of numbers")
    }
    var numbers: [Double] = []
    for element in elements {
      guard let number = element.numberValue else {
        throw FixtureError(description: "`\(what)` holds a value that is not a number")
      }
      numbers.append(number)
    }
    return numbers
  }

  /// Returns the positions of the array under a key, a line written as the fixture writes it.
  func positions(at key: String) throws(FixtureError) -> [[Double]] {
    var positions: [[Double]] = []
    for element in try array(at: key) {
      positions.append(try element.numberList(naming: key))
    }
    return positions
  }

  private func mistyped(_ key: String, expected: String) -> FixtureError {
    FixtureError(description: "the input's `\(key)` is not \(expected)")
  }
}

extension OrderedJSON {
  /// Returns a number for a whole or fractional count of milliseconds.
  static func milliseconds(_ duration: Duration) -> OrderedJSON {
    let (seconds, attoseconds) = duration.components
    return .number(Double(seconds) * 1000 + Double(attoseconds) / 1e15)
  }

  /// Returns a number for a whole or fractional count of seconds.
  static func seconds(_ duration: Duration) -> OrderedJSON {
    let (seconds, attoseconds) = duration.components
    return .number(Double(seconds) + Double(attoseconds) / 1e18)
  }
}
