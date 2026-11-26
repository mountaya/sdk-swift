/// OrderedJSON is a JSON value whose objects keep their members in document order.
///
/// Foundation's decoders hand an object back as a dictionary, which has no order, and a fixture
/// may carry meaning in the order of its keys: a field tree lists its fields in the order the
/// document prints them. This reader keeps what the file says.
///
/// `null`, an absent key and an empty object stay three different things, and a number written
/// `16` equals one written `16.0`.
package enum OrderedJSON: Sendable {
  case null
  case bool(Bool)
  case number(Double)
  case string(String)
  case array([OrderedJSON])
  case object([Member])

  /// Member is one key of an object and its value.
  package struct Member: Sendable {
    package let key: String
    package let value: OrderedJSON

    package init(key: String, value: OrderedJSON) {
      self.key = key
      self.value = value
    }
  }

  /// members is the object's members in document order, or nil for any other value.
  package var members: [Member]? {
    if case .object(let members) = self { return members }
    return nil
  }

  /// elements is the array's elements, or nil for any other value.
  package var elements: [OrderedJSON]? {
    if case .array(let elements) = self { return elements }
    return nil
  }

  /// stringValue is the string, or nil for any other value.
  package var stringValue: String? {
    if case .string(let value) = self { return value }
    return nil
  }

  /// numberValue is the number, or nil for any other value.
  package var numberValue: Double? {
    if case .number(let value) = self { return value }
    return nil
  }

  /// boolValue is the boolean, or nil for any other value.
  package var boolValue: Bool? {
    if case .bool(let value) = self { return value }
    return nil
  }

  /// isNull is true for JSON `null`, which is a value, and never for an absent key.
  package var isNull: Bool {
    if case .null = self { return true }
    return false
  }

  /// Returns the value under a key of an object, or nil when the key is absent or the value is
  /// not an object.
  package subscript(key: String) -> OrderedJSON? {
    members?.first { $0.key == key }?.value
  }
}

extension OrderedJSON: Equatable {
  /// Two objects are equal when they hold the same keys with equal values, in any order. Two
  /// strings are equal when they hold the same scalars, never by Swift's `String` equality, which
  /// is canonical equivalence: `é` written as one scalar and `e` followed by a combining acute
  /// accent are two texts, as the contract reads them (`sdk/SPEC.md` §7).
  package static func == (lhs: OrderedJSON, rhs: OrderedJSON) -> Bool {
    switch (lhs, rhs) {
    case (.null, .null):
      return true
    case (.bool(let left), .bool(let right)):
      return left == right
    case (.number(let left), .number(let right)):
      return left == right
    case (.string(let left), .string(let right)):
      return left.unicodeScalars.elementsEqual(right.unicodeScalars)
    case (.array(let left), .array(let right)):
      return left == right
    case (.object(let left), .object(let right)):
      guard left.count == right.count else { return false }
      return left.allSatisfy { member in
        right.first { $0.key == member.key }?.value == member.value
      }
    default:
      return false
    }
  }
}

/// OrderedJSONError says where a document stopped being JSON.
package struct OrderedJSONError: Error, Sendable, CustomStringConvertible {
  package let message: String
  package let line: Int
  package let column: Int

  package var description: String {
    "line \(line), column \(column): \(message)"
  }
}

extension OrderedJSON {
  /// parse reads one JSON document. It is strict: a trailing comma, a duplicate key, a comment
  /// or anything after the document is an error.
  package static func parse(_ text: String) throws(OrderedJSONError) -> OrderedJSON {
    var parser = Parser(bytes: Array(text.utf8))
    parser.skipWhitespace()
    let value = try parser.parseValue(depth: 0)
    parser.skipWhitespace()
    guard parser.index == parser.bytes.count else {
      throw parser.error("unexpected content after the document")
    }
    return value
  }

  /// serialized renders the value with two-space indentation, one member to a line and a colon
  /// followed by one space, which is the form the contract's own tooling writes. Members are
  /// written in the order they are held.
  package func serialized() -> String {
    var output = ""
    write(into: &output, indent: 0)
    return output
  }

  private func write(into output: inout String, indent: Int) {
    let pad = String(repeating: "  ", count: indent)
    switch self {
    case .null:
      output += "null"
    case .bool(let value):
      output += value ? "true" : "false"
    case .number(let value):
      output += OrderedJSON.render(number: value)
    case .string(let value):
      output += OrderedJSON.render(string: value)
    case .array(let elements):
      if elements.isEmpty {
        output += "[]"
        return
      }
      output += "[\n"
      for (position, element) in elements.enumerated() {
        output += pad + "  "
        element.write(into: &output, indent: indent + 1)
        output += position == elements.count - 1 ? "\n" : ",\n"
      }
      output += pad + "]"
    case .object(let members):
      if members.isEmpty {
        output += "{}"
        return
      }
      output += "{\n"
      for (position, member) in members.enumerated() {
        output += pad + "  " + OrderedJSON.render(string: member.key) + ": "
        member.value.write(into: &output, indent: indent + 1)
        output += position == members.count - 1 ? "\n" : ",\n"
      }
      output += pad + "}"
    }
  }

  private static func render(number: Double) -> String {
    if number == number.rounded(), abs(number) < 1e15 {
      return String(Int64(number))
    }
    return "\(number)"
  }

  private static func render(string: String) -> String {
    var output = "\""
    for scalar in string.unicodeScalars {
      switch scalar {
      case "\"": output += "\\\""
      case "\\": output += "\\\\"
      case "\n": output += "\\n"
      case "\r": output += "\\r"
      case "\t": output += "\\t"
      default:
        if scalar.value < 0x20 {
          let hex = String(scalar.value, radix: 16)
          output += "\\u" + String(repeating: "0", count: 4 - hex.count) + hex
        } else {
          output.unicodeScalars.append(scalar)
        }
      }
    }
    return output + "\""
  }
}

private struct Parser {
  let bytes: [UInt8]
  var index = 0

  /// The deepest nesting a document may reach, so a malformed file cannot exhaust the stack.
  static let maximumDepth = 256

  init(bytes: [UInt8]) {
    self.bytes = bytes
  }

  func error(_ message: String) -> OrderedJSONError {
    var line = 1
    var column = 1
    for byte in bytes[..<min(index, bytes.count)] {
      if byte == UInt8(ascii: "\n") {
        line += 1
        column = 1
      } else {
        column += 1
      }
    }
    return OrderedJSONError(message: message, line: line, column: column)
  }

  var current: UInt8? {
    index < bytes.count ? bytes[index] : nil
  }

  mutating func skipWhitespace() {
    while let byte = current, byte == 0x20 || byte == 0x0A || byte == 0x0D || byte == 0x09 {
      index += 1
    }
  }

  mutating func parseValue(depth: Int) throws(OrderedJSONError) -> OrderedJSON {
    guard depth <= Parser.maximumDepth else {
      throw error("the document nests deeper than \(Parser.maximumDepth) levels")
    }
    guard let byte = current else {
      throw error("unexpected end of the document")
    }
    switch byte {
    case UInt8(ascii: "{"):
      return try parseObject(depth: depth)
    case UInt8(ascii: "["):
      return try parseArray(depth: depth)
    case UInt8(ascii: "\""):
      return .string(try parseString())
    case UInt8(ascii: "t"):
      try expect(literal: "true")
      return .bool(true)
    case UInt8(ascii: "f"):
      try expect(literal: "false")
      return .bool(false)
    case UInt8(ascii: "n"):
      try expect(literal: "null")
      return .null
    case UInt8(ascii: "-"), UInt8(ascii: "0")...UInt8(ascii: "9"):
      return .number(try parseNumber())
    default:
      throw error("unexpected character")
    }
  }

  mutating func expect(literal: String) throws(OrderedJSONError) {
    for byte in literal.utf8 {
      guard current == byte else {
        throw error("expected `\(literal)`")
      }
      index += 1
    }
  }

  mutating func parseObject(depth: Int) throws(OrderedJSONError) -> OrderedJSON {
    index += 1
    var members: [OrderedJSON.Member] = []
    skipWhitespace()
    if current == UInt8(ascii: "}") {
      index += 1
      return .object(members)
    }
    while true {
      skipWhitespace()
      guard current == UInt8(ascii: "\"") else {
        throw error("expected a key")
      }
      let key = try parseString()
      if members.contains(where: { $0.key == key }) {
        throw error("the key \"\(key)\" appears twice in one object")
      }
      skipWhitespace()
      guard current == UInt8(ascii: ":") else {
        throw error("expected `:` after a key")
      }
      index += 1
      skipWhitespace()
      let value = try parseValue(depth: depth + 1)
      members.append(OrderedJSON.Member(key: key, value: value))
      skipWhitespace()
      if current == UInt8(ascii: ",") {
        index += 1
      } else if current == UInt8(ascii: "}") {
        index += 1
        return .object(members)
      } else {
        throw error("expected `,` or `}` in an object")
      }
    }
  }

  mutating func parseArray(depth: Int) throws(OrderedJSONError) -> OrderedJSON {
    index += 1
    var elements: [OrderedJSON] = []
    skipWhitespace()
    if current == UInt8(ascii: "]") {
      index += 1
      return .array(elements)
    }
    while true {
      skipWhitespace()
      elements.append(try parseValue(depth: depth + 1))
      skipWhitespace()
      if current == UInt8(ascii: ",") {
        index += 1
      } else if current == UInt8(ascii: "]") {
        index += 1
        return .array(elements)
      } else {
        throw error("expected `,` or `]` in an array")
      }
    }
  }

  mutating func parseNumber() throws(OrderedJSONError) -> Double {
    let start = index
    if current == UInt8(ascii: "-") {
      index += 1
    }
    guard let first = current, isDigit(first) else {
      throw error("expected a digit")
    }
    if first == UInt8(ascii: "0") {
      index += 1
    } else {
      skipDigits()
    }
    if current == UInt8(ascii: ".") {
      index += 1
      guard let digit = current, isDigit(digit) else {
        throw error("expected a digit after the decimal point")
      }
      skipDigits()
    }
    if current == UInt8(ascii: "e") || current == UInt8(ascii: "E") {
      index += 1
      if current == UInt8(ascii: "+") || current == UInt8(ascii: "-") {
        index += 1
      }
      guard let digit = current, isDigit(digit) else {
        throw error("expected a digit in the exponent")
      }
      skipDigits()
    }
    guard let value = Double(String(decoding: bytes[start..<index], as: UTF8.self)) else {
      throw error("the number does not fit a double")
    }
    return value
  }

  func isDigit(_ byte: UInt8) -> Bool {
    byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9")
  }

  mutating func skipDigits() {
    while let byte = current, isDigit(byte) {
      index += 1
    }
  }

  mutating func parseString() throws(OrderedJSONError) -> String {
    index += 1
    var buffer: [UInt8] = []
    while true {
      guard let byte = current else {
        throw error("unterminated string")
      }
      if byte == UInt8(ascii: "\"") {
        index += 1
        return String(decoding: buffer, as: UTF8.self)
      }
      if byte < 0x20 {
        throw error("a control character inside a string must be escaped")
      }
      if byte != UInt8(ascii: "\\") {
        buffer.append(byte)
        index += 1
        continue
      }
      index += 1
      guard let escape = current else {
        throw error("unterminated escape")
      }
      index += 1
      switch escape {
      case UInt8(ascii: "\""): buffer.append(UInt8(ascii: "\""))
      case UInt8(ascii: "\\"): buffer.append(UInt8(ascii: "\\"))
      case UInt8(ascii: "/"): buffer.append(UInt8(ascii: "/"))
      case UInt8(ascii: "b"): buffer.append(0x08)
      case UInt8(ascii: "f"): buffer.append(0x0C)
      case UInt8(ascii: "n"): buffer.append(0x0A)
      case UInt8(ascii: "r"): buffer.append(0x0D)
      case UInt8(ascii: "t"): buffer.append(0x09)
      case UInt8(ascii: "u"):
        let scalar = try parseEscapedScalar()
        buffer.append(contentsOf: Array(String(Character(scalar)).utf8))
      default:
        throw error("unknown escape")
      }
    }
  }

  /// Reads the four hex digits after `\u`, and the low half of a surrogate pair when the first
  /// is a high half.
  mutating func parseEscapedScalar() throws(OrderedJSONError) -> Unicode.Scalar {
    let first = try parseHexQuad()
    var value = first
    if (0xD800...0xDBFF).contains(first) {
      guard current == UInt8(ascii: "\\"), index + 1 < bytes.count,
        bytes[index + 1] == UInt8(ascii: "u")
      else {
        throw error("a high surrogate with no low surrogate after it")
      }
      index += 2
      let second = try parseHexQuad()
      guard (0xDC00...0xDFFF).contains(second) else {
        throw error("a high surrogate followed by something else")
      }
      value = 0x10000 + ((first - 0xD800) << 10) + (second - 0xDC00)
    }
    guard let scalar = Unicode.Scalar(value) else {
      throw error("an escape that names no Unicode scalar")
    }
    return scalar
  }

  mutating func parseHexQuad() throws(OrderedJSONError) -> UInt32 {
    var value: UInt32 = 0
    for _ in 0..<4 {
      guard let byte = current, let digit = hexValue(byte) else {
        throw error("expected four hexadecimal digits")
      }
      value = value << 4 | digit
      index += 1
    }
    return value
  }

  func hexValue(_ byte: UInt8) -> UInt32? {
    switch byte {
    case UInt8(ascii: "0")...UInt8(ascii: "9"): return UInt32(byte - UInt8(ascii: "0"))
    case UInt8(ascii: "a")...UInt8(ascii: "f"): return UInt32(byte - UInt8(ascii: "a")) + 10
    case UInt8(ascii: "A")...UInt8(ascii: "F"): return UInt32(byte - UInt8(ascii: "A")) + 10
    default: return nil
    }
  }
}
