/// JSONValue is a JSON value whose shape the contract leaves open: a property it types as any
/// value, and the envelope's metadata where an operation declares none.
///
/// A number is a `Double`, as JSON's own numbers are. An object's members keep no order, and a
/// member that is `null` is a member, apart from one that is absent.
public enum JSONValue: Sendable, Hashable {
  /// null is JSON's `null`.
  case null
  /// bool is `true` or `false`.
  case bool(Bool)
  /// number is any JSON number.
  case number(Double)
  /// string is a JSON string.
  case string(String)
  /// array is a JSON array, in its order.
  case array([JSONValue])
  /// object is a JSON object.
  case object([String: JSONValue])
}

extension JSONValue: Codable {
  /// Reads the value a decoder holds, whatever its shape.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode(Double.self) {
      self = .number(value)
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode([JSONValue].self) {
      self = .array(value)
    } else {
      self = .object(try container.decode([String: JSONValue].self))
    }
  }

  /// encode writes the value as the JSON it is.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .null:
      try container.encodeNil()
    case .bool(let value):
      try container.encode(value)
    case .number(let value):
      try container.encode(value)
    case .string(let value):
      try container.encode(value)
    case .array(let value):
      try container.encode(value)
    case .object(let value):
      try container.encode(value)
    }
  }
}

extension JSONValue: ExpressibleByNilLiteral {
  /// Creates `null`.
  public init(nilLiteral: ()) {
    self = .null
  }
}

extension JSONValue: ExpressibleByBooleanLiteral {
  /// Creates a boolean.
  public init(booleanLiteral value: Bool) {
    self = .bool(value)
  }
}

extension JSONValue: ExpressibleByIntegerLiteral {
  /// Creates a number from an integer literal.
  public init(integerLiteral value: Int) {
    self = .number(Double(value))
  }
}

extension JSONValue: ExpressibleByFloatLiteral {
  /// Creates a number.
  public init(floatLiteral value: Double) {
    self = .number(value)
  }
}

extension JSONValue: ExpressibleByStringLiteral {
  /// Creates a string.
  public init(stringLiteral value: String) {
    self = .string(value)
  }
}

extension JSONValue: ExpressibleByArrayLiteral {
  /// Creates an array.
  public init(arrayLiteral elements: JSONValue...) {
    self = .array(elements)
  }
}

extension JSONValue: ExpressibleByDictionaryLiteral {
  /// Creates an object. A key written twice takes its last value.
  public init(dictionaryLiteral elements: (String, JSONValue)...) {
    self = .object(Dictionary(elements, uniquingKeysWith: { _, last in last }))
  }
}
