import MountayaClient

/// sameJson tells whether two JSON values state the same thing, member by member: a number by the
/// same-number relation, `NaN` the same as `NaN` and 0 another than -0, a string by its scalars, an
/// array element by element in order, and an object key by key in any order.
///
/// It reads the two with a stack of its own and never by recursion, so two values nested by the
/// thousand compare without reaching the end of the runtime's stack. `JSONValue`'s own `==` reads
/// numbers by IEEE equality and strings by canonical equivalence. It is the package's, so a value
/// of the map, a layer among them, compares the JSON it holds as every Geo value does, and no
/// consumer's: every value that holds JSON is `Hashable` by it.
package func sameJson(_ a: JSONValue, _ b: JSONValue) -> Bool {
  var pending = [(a, b)]
  while let (left, right) = pending.popLast() {
    switch (left, right) {
    case (.null, .null):
      continue
    case (.bool(let left), .bool(let right)):
      guard left == right else { return false }
    case (.number(let left), .number(let right)):
      guard sameNumber(left, right) else { return false }
    case (.string(let left), .string(let right)):
      guard sameText(left, right) else { return false }
    case (.array(let left), .array(let right)):
      guard left.count == right.count else { return false }
      pending.append(contentsOf: zip(left, right))
    case (.object(let left), .object(let right)):
      guard left.count == right.count else { return false }
      for (key, value) in left {
        guard let held = right[key] else { return false }
        pending.append((value, held))
      }
    default:
      return false
    }
  }
  return true
}

/// sameJson tells whether two JSON objects hold the same members, as `sameJson(_:_:)` reads two
/// values.
package func sameJson(_ a: [String: JSONValue], _ b: [String: JSONValue]) -> Bool {
  sameJson(.object(a), .object(b))
}

extension Hasher {
  /// Feeds a JSON value as `sameJson(_:_:)` reads it, so two values it calls the same hash alike:
  /// a number as the same-number relation reads it, and an object's members in no order.
  mutating func combine(sameJson value: JSONValue) {
    switch value {
    case .null:
      combine(0)
    case .bool(let flag):
      combine(1)
      combine(flag)
    case .number(let number):
      combine(2)
      combine(sameNumber: number)
    case .string(let text):
      combine(3)
      combine(text)
    case .array(let elements):
      combine(4)
      combine(elements.count)
      for element in elements {
        combine(sameJson: element)
      }
    case .object(let members):
      combine(5)
      combine(sameJson: members)
    }
  }

  /// Feeds a JSON object's members in no order, each key with its value.
  mutating func combine(sameJson members: [String: JSONValue]) {
    var commutative = 0
    for (key, value) in members {
      var member = Hasher()
      member.combine(key)
      member.combine(sameJson: value)
      commutative ^= member.finalize()
    }
    combine(members.count)
    combine(commutative)
  }
}
