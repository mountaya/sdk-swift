/// SourceToken is one token of Swift source, with the line it starts on.
package struct SourceToken: Sendable, Hashable {
  /// Kind tells a word from a number from a single character of punctuation, and, where a scan
  /// asks for them, a string literal from all three.
  package enum Kind: Sendable, Hashable {
    case identifier
    case number
    case punctuation
    /// string is a string literal, its text as written between its delimiters, each
    /// interpolation written `\(…)`; only `SwiftLexer.lex(_:keepingStrings:)` emits one.
    case string
  }

  package let kind: Kind
  package let text: String
  package let line: Int

  package init(kind: Kind, text: String, line: Int) {
    self.kind = kind
    self.text = text
    self.line = line
  }
}

/// SourceComment is one comment, without its delimiters, with the line it starts on.
package struct SourceComment: Sendable, Hashable {
  package let text: String
  package let line: Int
}

/// LexedSource is a file reduced to what a scan may match: its code tokens, and its comments
/// kept apart from them.
package struct LexedSource: Sendable {
  package let tokens: [SourceToken]
  package let comments: [SourceComment]
}

/// SwiftLexer splits Swift source into tokens, leaving out comments and, unless a scan asks to
/// read them, the text of string literals, so a scan for a name never matches a sentence that
/// merely mentions it.
///
/// It is a scanner, not a parser, and it knows three things a regular expression does not:
/// block comments nest, a string literal may be raw or multi-line, and the code inside an
/// interpolation is code. An attribute and a compiler directive are one token each
/// (`@testable`, `#if`), a backticked identifier is its bare name, and every other character
/// of punctuation is a token of its own.
///
/// One construct is out of its reach: a regular expression literal written with bare slashes
/// reads as two division operators with code between them. The extended form, with pound
/// signs, is skipped whole.
package enum SwiftLexer {
  /// lex returns the tokens and the comments of a source file.
  package static func lex(_ source: String) -> LexedSource {
    lex(source, keepingStrings: false)
  }

  /// lex returns the tokens and the comments of a source file, each string literal one token of
  /// kind `string` where `keepingStrings` asks for them, placed where the literal starts, before
  /// the code of its interpolations: a scan that reads a literal's text, such as a test's title,
  /// reads it from there, and every other scan asks for none.
  package static func lex(_ source: String, keepingStrings: Bool) -> LexedSource {
    var scanner = Scanner(scalars: Array(source.unicodeScalars), keepsStrings: keepingStrings)
    scanner.scanCode(untilClosingParenthesis: false)
    return LexedSource(tokens: scanner.tokens, comments: scanner.comments)
  }
}

private struct Scanner {
  let scalars: [Unicode.Scalar]
  /// keepsStrings is whether a string literal is emitted as a token of its own.
  let keepsStrings: Bool
  var index = 0
  var line = 1
  var tokens: [SourceToken] = []
  var comments: [SourceComment] = []

  init(scalars: [Unicode.Scalar], keepsStrings: Bool) {
    self.scalars = scalars
    self.keepsStrings = keepsStrings
  }

  func peek(_ offset: Int = 0) -> Unicode.Scalar? {
    let position = index + offset
    return position < scalars.count ? scalars[position] : nil
  }

  /// Scans code up to the end of the input, or, inside an interpolation, up to and including
  /// the parenthesis that closes it.
  mutating func scanCode(untilClosingParenthesis: Bool) {
    var depth = 0
    while let scalar = peek() {
      if scalar == "\n" {
        line += 1
        index += 1
      } else if scalar.properties.isWhitespace {
        index += 1
      } else if scalar == "/", peek(1) == "/" {
        scanLineComment()
      } else if scalar == "/", peek(1) == "*" {
        scanBlockComment()
      } else if scalar == "\"" {
        scanString(pounds: 0)
      } else if scalar == "#", let pounds = poundRun(), peek(pounds) == "\"" {
        index += pounds
        scanString(pounds: pounds)
      } else if scalar == "#", let pounds = poundRun(), peek(pounds) == "/" {
        scanExtendedRegex(pounds: pounds)
      } else if scalar == "#", let next = peek(1), isIdentifierHead(next) {
        index += 1
        emitWord(prefix: "#")
      } else if scalar == "@", let next = peek(1), isIdentifierHead(next) {
        index += 1
        emitWord(prefix: "@")
      } else if scalar == "`" {
        scanBacktickedIdentifier()
      } else if isIdentifierHead(scalar) {
        emitWord(prefix: "")
      } else if isDigit(scalar) {
        scanNumber()
      } else {
        if scalar == "(" {
          depth += 1
        } else if scalar == ")" {
          if depth == 0, untilClosingParenthesis {
            index += 1
            return
          }
          depth -= 1
        }
        tokens.append(SourceToken(kind: .punctuation, text: String(scalar), line: line))
        index += 1
      }
    }
  }

  /// Returns the length of the run of pound signs at the cursor.
  func poundRun() -> Int? {
    var count = 0
    while peek(count) == "#" {
      count += 1
    }
    return count > 0 ? count : nil
  }

  mutating func scanLineComment() {
    let start = line
    index += 2
    var text = String.UnicodeScalarView()
    while let scalar = peek(), scalar != "\n" {
      text.append(scalar)
      index += 1
    }
    comments.append(SourceComment(text: String(text), line: start))
  }

  mutating func scanBlockComment() {
    let start = line
    index += 2
    var depth = 1
    var text = String.UnicodeScalarView()
    while let scalar = peek() {
      if scalar == "/", peek(1) == "*" {
        depth += 1
        text.append(contentsOf: ["/", "*"])
        index += 2
      } else if scalar == "*", peek(1) == "/" {
        depth -= 1
        index += 2
        if depth == 0 {
          break
        }
        text.append(contentsOf: ["*", "/"])
      } else {
        if scalar == "\n" {
          line += 1
        }
        text.append(scalar)
        index += 1
      }
    }
    comments.append(SourceComment(text: String(text), line: start))
  }

  /// Scans a string literal whose opening quote is at the cursor, the pound signs of a raw
  /// literal already consumed. The literal's text is dropped, unless the scan keeps strings,
  /// which emits it as one token where the literal starts; the code of each interpolation is
  /// scanned as code.
  mutating func scanString(pounds: Int) {
    let start = line
    let position = tokens.count
    var text = String.UnicodeScalarView()
    defer {
      if keepsStrings {
        tokens.insert(SourceToken(kind: .string, text: String(text), line: start), at: position)
      }
    }
    let multiline = peek(1) == "\"" && peek(2) == "\""
    index += multiline ? 3 : 1
    while let scalar = peek() {
      if scalar == "\\", hasPounds(pounds, at: 1) {
        index += 1 + pounds
        if peek() == "(" {
          index += 1
          text.append(contentsOf: "\\(…)".unicodeScalars)
          scanCode(untilClosingParenthesis: true)
        } else if let escaped = peek() {
          if escaped == "\n" {
            line += 1
          }
          text.append("\\")
          text.append(escaped)
          index += 1
        }
      } else if scalar == "\"" {
        if multiline {
          if peek(1) == "\"", peek(2) == "\"", hasPounds(pounds, at: 3) {
            index += 3 + pounds
            return
          }
          text.append(scalar)
          index += 1
        } else if hasPounds(pounds, at: 1) {
          index += 1 + pounds
          return
        } else {
          text.append(scalar)
          index += 1
        }
      } else if scalar == "\n" {
        if !multiline {
          // An unterminated single-line literal ends with its line, so one stray quote
          // cannot swallow the rest of the file.
          return
        }
        text.append(scalar)
        line += 1
        index += 1
      } else {
        text.append(scalar)
        index += 1
      }
    }
  }

  func hasPounds(_ count: Int, at offset: Int) -> Bool {
    for position in 0..<count where peek(offset + position) != "#" {
      return false
    }
    return true
  }

  mutating func scanExtendedRegex(pounds: Int) {
    index += pounds + 1
    while let scalar = peek() {
      if scalar == "/", hasPounds(pounds, at: 1) {
        index += 1 + pounds
        return
      }
      if scalar == "\n" {
        line += 1
      }
      index += 1
    }
  }

  mutating func scanBacktickedIdentifier() {
    let start = line
    index += 1
    var text = String.UnicodeScalarView()
    while let scalar = peek(), scalar != "`", scalar != "\n" {
      text.append(scalar)
      index += 1
    }
    if peek() == "`" {
      index += 1
    }
    tokens.append(SourceToken(kind: .identifier, text: String(text), line: start))
  }

  mutating func emitWord(prefix: String) {
    var text = String.UnicodeScalarView()
    text.append(contentsOf: prefix.unicodeScalars)
    while let scalar = peek(), isIdentifierBody(scalar) {
      text.append(scalar)
      index += 1
    }
    tokens.append(SourceToken(kind: .identifier, text: String(text), line: line))
  }

  mutating func scanNumber() {
    var text = String.UnicodeScalarView()
    while let scalar = peek() {
      if isIdentifierBody(scalar) {
        text.append(scalar)
        index += 1
        // A sign belongs to the number only as the sign of an exponent.
        if (scalar == "e" || scalar == "E" || scalar == "p" || scalar == "P"),
          let sign = peek(), sign == "-" || sign == "+", let digit = peek(1), isDigit(digit)
        {
          text.append(sign)
          index += 1
        }
      } else if scalar == ".", let next = peek(1), isDigit(next) {
        // A point belongs to the number only when a digit follows, so `0..<1` is two numbers.
        text.append(scalar)
        index += 1
      } else {
        break
      }
    }
    tokens.append(SourceToken(kind: .number, text: String(text), line: line))
  }

  func isDigit(_ scalar: Unicode.Scalar) -> Bool {
    scalar >= "0" && scalar <= "9"
  }

  func isIdentifierHead(_ scalar: Unicode.Scalar) -> Bool {
    scalar == "_" || scalar == "$" || scalar.properties.isAlphabetic
  }

  func isIdentifierBody(_ scalar: Unicode.Scalar) -> Bool {
    isIdentifierHead(scalar) || isDigit(scalar)
  }
}
