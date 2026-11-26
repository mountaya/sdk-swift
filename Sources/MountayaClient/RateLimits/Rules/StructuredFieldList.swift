import Foundation

/// StructuredFieldList reads a Structured Field List, as RFC 9651 section 4.2 has a recipient
/// parse one.
///
/// A field that does not parse is ignored whole, which is what the RFC has a recipient do, so
/// the reader answers nil for it rather than the members before the fault.
enum StructuredFieldList {
  /// Item is a bare item.
  enum Item: Sendable, Hashable {
    case integer(Int64)
    case decimal(Double)
    case string(String)
    case token(String)
    case bytes([UInt8])
    case boolean(Bool)
    case date(Int64)
    case displayString(String)
  }

  /// Member is one member of the list: an item, or an inner list of them, with its parameters
  /// in the order they were written, a key written twice holding its last value.
  enum Member: Sendable, Hashable {
    case item(Item, parameters: [Parameter])
    case innerList([InnerItem], parameters: [Parameter])
  }

  /// InnerItem is one item of an inner list, with its parameters.
  struct InnerItem: Sendable, Hashable {
    let item: Item
    let parameters: [Parameter]
  }

  /// Parameter is one parameter of an item or an inner list.
  struct Parameter: Sendable, Hashable {
    let key: String
    let value: Item
  }

  /// parse returns the members of a field's value, or nil where it does not parse.
  static func parse(_ text: String) -> [Member]? {
    var reader = Reader(Array(text.utf8))
    return reader.list()
  }

  /// Reader walks a field's bytes once, each step consuming what it read.
  private struct Reader {
    private let bytes: [UInt8]
    private var position = 0

    init(_ bytes: [UInt8]) {
      self.bytes = bytes
    }

    private var current: UInt8? {
      position < bytes.count ? bytes[position] : nil
    }

    private var isAtEnd: Bool {
      position >= bytes.count
    }

    mutating func list() -> [Member]? {
      skip(while: { $0 == space })
      var members: [Member] = []
      while !isAtEnd {
        guard let member = member() else { return nil }
        members.append(member)
        skip(while: { $0 == space || $0 == tab })
        if isAtEnd {
          return members
        }
        guard current == comma else { return nil }
        position += 1
        skip(while: { $0 == space || $0 == tab })
        if isAtEnd {
          return nil
        }
      }
      return members
    }

    private mutating func member() -> Member? {
      if current == openParenthesis {
        guard let items = innerList(), let parameters = parameters() else { return nil }
        return .innerList(items, parameters: parameters)
      }
      guard let item = bareItem(), let parameters = parameters() else { return nil }
      return .item(item, parameters: parameters)
    }

    private mutating func innerList() -> [InnerItem]? {
      position += 1
      var items: [InnerItem] = []
      while !isAtEnd {
        skip(while: { $0 == space })
        if current == closeParenthesis {
          position += 1
          return items
        }
        guard let item = bareItem(), let parameters = parameters() else { return nil }
        items.append(InnerItem(item: item, parameters: parameters))
        guard current == space || current == closeParenthesis else { return nil }
      }
      return nil
    }

    private mutating func parameters() -> [Parameter]? {
      var parameters: [Parameter] = []
      while current == semicolon {
        position += 1
        skip(while: { $0 == space })
        guard let key = key() else { return nil }
        var value = Item.boolean(true)
        if current == equals {
          position += 1
          guard let read = bareItem() else { return nil }
          value = read
        }
        parameters.removeAll { $0.key == key }
        parameters.append(Parameter(key: key, value: value))
      }
      return parameters
    }

    private mutating func key() -> String? {
      guard let first = current, isLowercaseLetter(first) || first == asterisk else { return nil }
      let start = position
      skip(while: {
        isLowercaseLetter($0) || isDigit($0) || [underscore, hyphen, period, asterisk].contains($0)
      })
      return String(decoding: bytes[start..<position], as: UTF8.self)
    }

    private mutating func bareItem() -> Item? {
      guard let first = current else { return nil }
      if first == hyphen || isDigit(first) {
        return number()
      }
      if first == quote {
        return string().map(Item.string)
      }
      if isLetter(first) || first == asterisk {
        return .token(token())
      }
      if first == colon {
        return byteSequence().map(Item.bytes)
      }
      if first == question {
        return boolean().map(Item.boolean)
      }
      if first == at {
        position += 1
        guard case .integer(let seconds)? = number() else { return nil }
        return .date(seconds)
      }
      if first == percent {
        return displayString().map(Item.displayString)
      }
      return nil
    }

    private mutating func number() -> Item? {
      var negative = false
      if current == hyphen {
        negative = true
        position += 1
      }
      guard let first = current, isDigit(first) else { return nil }
      var integerDigits: [UInt8] = []
      var fractionDigits: [UInt8] = []
      var isDecimal = false
      while let byte = current {
        if isDigit(byte) {
          if isDecimal {
            fractionDigits.append(byte)
          } else {
            integerDigits.append(byte)
          }
          position += 1
        } else if byte == period, !isDecimal {
          guard integerDigits.count <= 12 else { return nil }
          isDecimal = true
          position += 1
        } else {
          break
        }
        if !isDecimal, integerDigits.count > 15 { return nil }
        if isDecimal, fractionDigits.count > 3 { return nil }
      }
      if isDecimal {
        guard !fractionDigits.isEmpty else { return nil }
        let text = String(decoding: integerDigits + [period] + fractionDigits, as: UTF8.self)
        guard let value = Double(text) else { return nil }
        return .decimal(negative ? -value : value)
      }
      guard let value = Int64(String(decoding: integerDigits, as: UTF8.self)) else { return nil }
      return .integer(negative ? -value : value)
    }

    private mutating func string() -> String? {
      position += 1
      var characters: [UInt8] = []
      while let byte = current {
        position += 1
        if byte == backslash {
          guard let escaped = current, escaped == quote || escaped == backslash else { return nil }
          characters.append(escaped)
          position += 1
        } else if byte == quote {
          return String(decoding: characters, as: UTF8.self)
        } else if byte < 0x20 || byte > 0x7E {
          return nil
        } else {
          characters.append(byte)
        }
      }
      return nil
    }

    private mutating func token() -> String {
      let start = position
      position += 1
      skip(while: { isTokenCharacter($0) || $0 == colon || $0 == slash })
      return String(decoding: bytes[start..<position], as: UTF8.self)
    }

    private mutating func byteSequence() -> [UInt8]? {
      position += 1
      let start = position
      skip(while: { isLetter($0) || isDigit($0) || $0 == plus || $0 == slash || $0 == equals })
      guard current == colon else { return nil }
      let encoded = Array(bytes[start..<position])
      position += 1
      return Base64.decode(encoded)
    }

    private mutating func boolean() -> Bool? {
      position += 1
      switch current {
      case UInt8(ascii: "1"):
        position += 1
        return true
      case UInt8(ascii: "0"):
        position += 1
        return false
      default:
        return nil
      }
    }

    private mutating func displayString() -> String? {
      position += 1
      guard current == quote else { return nil }
      position += 1
      var decoded: [UInt8] = []
      while let byte = current {
        position += 1
        if byte == percent {
          guard position + 1 < bytes.count,
            let high = lowercaseHexValue(bytes[position]),
            let low = lowercaseHexValue(bytes[position + 1])
          else {
            return nil
          }
          decoded.append(high << 4 | low)
          position += 2
        } else if byte == quote {
          return String(bytes: decoded, encoding: .utf8)
        } else if byte < 0x20 || byte > 0x7E {
          return nil
        } else {
          decoded.append(byte)
        }
      }
      return nil
    }

    private mutating func skip(while matches: (UInt8) -> Bool) {
      while let byte = current, matches(byte) {
        position += 1
      }
    }
  }

  private static let space = UInt8(ascii: " ")
  private static let tab = UInt8(ascii: "\t")
  private static let comma = UInt8(ascii: ",")
  private static let semicolon = UInt8(ascii: ";")
  private static let equals = UInt8(ascii: "=")
  private static let quote = UInt8(ascii: "\"")
  private static let backslash = UInt8(ascii: "\\")
  private static let colon = UInt8(ascii: ":")
  private static let question = UInt8(ascii: "?")
  private static let at = UInt8(ascii: "@")
  private static let percent = UInt8(ascii: "%")
  private static let hyphen = UInt8(ascii: "-")
  private static let period = UInt8(ascii: ".")
  private static let asterisk = UInt8(ascii: "*")
  private static let underscore = UInt8(ascii: "_")
  private static let slash = UInt8(ascii: "/")
  private static let plus = UInt8(ascii: "+")
  private static let openParenthesis = UInt8(ascii: "(")
  private static let closeParenthesis = UInt8(ascii: ")")

  private static func isDigit(_ byte: UInt8) -> Bool {
    byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9")
  }

  private static func isLowercaseLetter(_ byte: UInt8) -> Bool {
    byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "z")
  }

  private static func isLetter(_ byte: UInt8) -> Bool {
    isLowercaseLetter(byte) || (byte >= UInt8(ascii: "A") && byte <= UInt8(ascii: "Z"))
  }

  /// isTokenCharacter is RFC 9110's `tchar`.
  private static func isTokenCharacter(_ byte: UInt8) -> Bool {
    isLetter(byte) || isDigit(byte) || Array("!#$%&'*+-.^_`|~".utf8).contains(byte)
  }

  private static func lowercaseHexValue(_ byte: UInt8) -> UInt8? {
    if isDigit(byte) {
      return byte - UInt8(ascii: "0")
    }
    if byte >= UInt8(ascii: "a"), byte <= UInt8(ascii: "f") {
      return byte - UInt8(ascii: "a") + 10
    }
    return nil
  }

  /// Base64 decodes RFC 4648's alphabet with its padding, as a byte sequence carries it.
  private enum Base64 {
    static func decode(_ encoded: [UInt8]) -> [UInt8]? {
      var value: UInt32 = 0
      var bits = 0
      var decoded: [UInt8] = []
      for byte in encoded where byte != StructuredFieldList.equals {
        guard let sextet = sextet(byte) else { return nil }
        value = value << 6 | UInt32(sextet)
        bits += 6
        if bits >= 8 {
          bits -= 8
          decoded.append(UInt8(truncatingIfNeeded: value >> UInt32(bits)))
        }
      }
      return decoded
    }

    private static func sextet(_ byte: UInt8) -> UInt8? {
      switch byte {
      case UInt8(ascii: "A")...UInt8(ascii: "Z"): byte - UInt8(ascii: "A")
      case UInt8(ascii: "a")...UInt8(ascii: "z"): byte - UInt8(ascii: "a") + 26
      case UInt8(ascii: "0")...UInt8(ascii: "9"): byte - UInt8(ascii: "0") + 52
      case UInt8(ascii: "+"): 62
      case UInt8(ascii: "/"): 63
      default: nil
      }
    }
  }
}
