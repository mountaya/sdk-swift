import GateSupport

/// Fixture is one golden file: the cases that prove a capability, and what they share.
struct Fixture: Sendable {
  let capability: String
  let cases: [FixtureCase]
  let tolerance: Tolerance?
  /// document is the whole file, for a runner that reads `constants`, `defaults` or `copy`.
  let document: OrderedJSON

  /// Returns the fixture's `constants` member, when it declares one.
  var constants: OrderedJSON? { document["constants"] }

  /// Returns the fixture's `defaults` member, when it declares one.
  var defaults: OrderedJSON? { document["defaults"] }

  /// Returns the fixture's `copy` member, when it declares one.
  var copy: OrderedJSON? { document["copy"] }
}

/// FixtureCase is one input and the exact output the contract expects for it.
struct FixtureCase: Sendable {
  let name: String
  let input: OrderedJSON
  let expect: OrderedJSON
}

/// FixtureError says why a golden file could not be read as a fixture.
struct FixtureError: Error, Sendable, CustomStringConvertible {
  let description: String
}

extension Fixture {
  /// parse reads a golden file's text.
  ///
  /// A fixture is never repaired here: a file that is not the shape the contract describes is
  /// an error, since a case silently dropped is a rule silently unproven.
  static func parse(_ text: String, path: String) throws(FixtureError) -> Fixture {
    let parsed: OrderedJSON
    do {
      parsed = try OrderedJSON.parse(text)
    } catch {
      throw FixtureError(description: "\(path) is not JSON: \(error)")
    }
    let document = try decodingNumbers(parsed, in: path)
    guard let capability = document["capability"]?.stringValue else {
      throw FixtureError(description: "\(path) names no capability")
    }
    guard let entries = document["cases"]?.elements, !entries.isEmpty else {
      throw FixtureError(description: "\(path) holds no cases")
    }
    var cases: [FixtureCase] = []
    for entry in entries {
      guard let name = entry["name"]?.stringValue, let input = entry["input"],
        let expect = entry["expect"]
      else {
        throw FixtureError(
          description: "\(path) holds a case without a name, an input or an expect")
      }
      guard !cases.contains(where: { $0.name == name }) else {
        throw FixtureError(description: "\(path) names the case `\(name)` twice")
      }
      cases.append(FixtureCase(name: name, input: input, expect: expect))
    }
    var tolerance: Tolerance?
    if let declared = document["tolerance"] {
      guard let parsed = Tolerance(declared) else {
        throw FixtureError(description: "\(path) declares a tolerance this harness cannot read")
      }
      tolerance = parsed
    }
    return Fixture(capability: capability, cases: cases, tolerance: tolerance, document: document)
  }

  /// The spellings `sdk/SPEC.md` section 10 gives the numbers JSON cannot carry.
  private static let nonFinite: [String: Double] = [
    "NaN": .nan,
    "Infinity": .infinity,
    "-Infinity": -.infinity,
  ]

  /// decodingNumbers returns a value with every `{ "$number": ... }` in it replaced by the number
  /// it spells, before any case runs or is compared.
  ///
  /// An object naming `$number` is that number or a malformed fixture: one beside other keys, or
  /// holding any other value, is refused, as the contract's own `check:sdk` refuses it.
  static func decodingNumbers(_ value: OrderedJSON, in path: String) throws(FixtureError)
    -> OrderedJSON
  {
    switch value {
    case .array(let elements):
      var decoded: [OrderedJSON] = []
      for element in elements {
        decoded.append(try decodingNumbers(element, in: path))
      }
      return .array(decoded)
    case .object(let members):
      if let spelled = value["$number"] {
        guard members.count == 1, let name = spelled.stringValue, let number = nonFinite[name]
        else {
          throw FixtureError(
            description: "\(path) holds a `$number` that is not NaN, Infinity or -Infinity alone"
          )
        }
        return .number(number)
      }
      var decoded: [OrderedJSON.Member] = []
      for member in members {
        decoded.append(
          OrderedJSON.Member(key: member.key, value: try decodingNumbers(member.value, in: path))
        )
      }
      return .object(decoded)
    case .null, .bool, .number, .string:
      return value
    }
  }
}
