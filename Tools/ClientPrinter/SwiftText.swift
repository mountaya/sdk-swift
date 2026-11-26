import Foundation

/// SwiftText spells a contract name or value as Swift source.
enum SwiftText {
  /// The column no printed line passes, which is the formatter's own.
  static let lineLength = 100

  /// Words Swift reserves, which a name spells in backticks to be used as an identifier.
  private static let keywords: Set<String> = [
    "Any", "Protocol", "Self", "Type", "_", "as", "associatedtype", "await", "break", "case",
    "catch", "class", "continue", "default", "defer", "deinit", "do", "else", "enum",
    "extension", "fallthrough", "false", "fileprivate", "for", "func", "guard", "if", "import",
    "in", "init", "inout", "internal", "is", "let", "nil", "open", "operator", "precedencegroup",
    "private", "protocol", "public", "repeat", "rethrows", "return", "self", "static", "struct",
    "subscript", "super", "switch", "throw", "throws", "true", "try", "typealias", "var",
    "where", "while",
  ]

  /// identifier spells a name as a Swift identifier: as it is where Swift reads it as one, and
  /// in backticks otherwise, which makes a keyword or a name such as `Last-Event-ID` a raw
  /// identifier the contract's spelling survives in.
  static func identifier(_ name: String) -> String {
    isPlain(name) && !keywords.contains(name) ? name : "`\(name)`"
  }

  /// isPlain is true for a name made of ASCII letters, digits and underscores, not starting
  /// with a digit.
  static func isPlain(_ name: String) -> Bool {
    guard let first = name.unicodeScalars.first, !("0"..."9").contains(first) else {
      return false
    }
    return name.unicodeScalars.allSatisfy {
      ("A"..."Z").contains($0) || ("a"..."z").contains($0) || ("0"..."9").contains($0)
        || $0 == "_"
    }
  }

  /// literal spells a string as a Swift string literal.
  static func literal(_ text: String) -> String {
    var escaped = ""
    for scalar in text.unicodeScalars {
      switch scalar {
      case "\\": escaped += "\\\\"
      case "\"": escaped += "\\\""
      case "\n": escaped += "\\n"
      case "\r": escaped += "\\r"
      case "\t": escaped += "\\t"
      default:
        if scalar.value < 0x20 {
          escaped += "\\u{\(String(scalar.value, radix: 16))}"
        } else {
          escaped.unicodeScalars.append(scalar)
        }
      }
    }
    return "\"\(escaped)\""
  }

  /// upperFirst uppercases a name's first letter, which is how a synthesized type name is
  /// built from an operation's: `postItineraryPreview` gives `PostItineraryPreview`.
  static func upperFirst(_ name: String) -> String {
    name.prefix(1).uppercased() + name.dropFirst()
  }

  /// docLines renders text as `///` lines at an indentation, each line kept within the
  /// formatter's column by breaking at spaces, and a blank line kept as a bare `///`.
  static func docLines(_ text: String, indent: Int) -> [String] {
    let prefix = String(repeating: " ", count: indent) + "///"
    let width = lineLength - prefix.count - 1
    var lines: [String] = []
    for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
      let line = String(raw).trimmingTrailingSpaces()
      if line.isEmpty {
        lines.append(prefix)
        continue
      }
      for piece in wrap(line, width: width) {
        lines.append(prefix + " " + piece)
      }
    }
    while lines.last == prefix {
      lines.removeLast()
    }
    return lines
  }

  /// wrap breaks a line at spaces so each piece fits `width`, keeping the line's own leading
  /// spaces on each continuation, and leaves a word longer than `width` whole.
  private static func wrap(_ line: String, width: Int) -> [String] {
    guard line.count > width else { return [line] }
    let leading = String(line.prefix { $0 == " " })
    let words = line.dropFirst(leading.count).split(separator: " ")
    var pieces: [String] = []
    var current = leading
    for word in words {
      if current.count > leading.count, current.count + 1 + word.count > width {
        pieces.append(current)
        current = leading
      }
      current += (current.count > leading.count ? " " : "") + word
    }
    pieces.append(current)
    return pieces
  }

  /// oneLine is a text on one line: every run of spaces and line breaks one space, and none at
  /// either end.
  static func oneLine(_ text: String) -> String {
    text.split(whereSeparator: { $0 == " " || $0.isNewline }).joined(separator: " ")
  }

  /// firstSentence is a description's first sentence, on one line, which is what a deprecation
  /// message carries.
  static func firstSentence(_ text: String) -> String {
    let paragraph = text.components(separatedBy: "\n\n").first ?? text
    let flat = paragraph.split(whereSeparator: \.isNewline).joined(separator: " ")
    if let end = flat.range(of: ". ") {
      return String(flat[..<end.lowerBound]) + "."
    }
    return flat
  }
}

extension String {
  fileprivate func trimmingTrailingSpaces() -> String {
    var text = self
    while text.last == " " || text.last == "\t" {
      text.removeLast()
    }
    return text
  }
}
