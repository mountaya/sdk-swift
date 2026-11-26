import GateSupport
import Testing

@Suite("SwiftLexer")
struct SwiftLexerTests {
  private func words(_ source: String) -> [String] {
    SwiftLexer.lex(source).tokens.map(\.text)
  }

  @Test("a line comment and a block comment are not code")
  func commentsAreNotCode() {
    let source = """
      let a = 1 // Date() is only mentioned here
      /* UUID() too, /* even nested */ still a comment */
      let b = 2
      """
    let lexed = SwiftLexer.lex(source)

    #expect(lexed.tokens.map(\.text) == ["let", "a", "=", "1", "let", "b", "=", "2"])
    #expect(lexed.comments.count == 2)
    #expect(lexed.comments.first?.text == " Date() is only mentioned here")
    #expect(lexed.comments.first?.line == 1)
  }

  @Test("the text of a string literal is not code")
  func stringTextIsNotCode() {
    #expect(words(#"let a = "Date() and UserDefaults""#) == ["let", "a", "="])
    #expect(words(#"let a = "an escaped \" quote, then Date()""#) == ["let", "a", "="])
  }

  @Test("the code inside an interpolation is code")
  func interpolationIsCode() {
    #expect(
      words(#"let a = "now: \(Date()) and \(f("x", (1)))""#)
        == ["let", "a", "=", "Date", "(", ")", "f", "(", ",", "(", "1", ")", ")"]
    )
  }

  @Test("a multi-line literal and a raw literal are skipped whole")
  func multilineAndRawLiterals() {
    let multiline = "let a = \"\"\"\n  Date() with a \" quote\n  \"\"\"\nlet b = 2"
    #expect(words(multiline) == ["let", "a", "=", "let", "b", "=", "2"])

    let raw = "let a = #\"a \"quoted\" \\(notCode) word\"#\nlet b = #\"\\#(code)\"#"
    #expect(words(raw) == ["let", "a", "=", "let", "b", "=", "code"])
  }

  @Test("an extended regular expression literal is skipped whole")
  func extendedRegexLiteral() {
    #expect(
      words(##"let a = #/Date\(\)"/# ; let b = 2"##) == [
        "let", "a", "=", ";", "let", "b", "=", "2",
      ])
  }

  @Test("an attribute and a directive are one token each, and a backticked name is bare")
  func attributesDirectivesAndBackticks() {
    #expect(words("@testable import Foo") == ["@testable", "import", "Foo"])
    #expect(words("#if canImport(Bar)") == ["#if", "canImport", "(", "Bar", ")"])
    #expect(words("var `Last-Event-ID`: Int") == ["var", "Last-Event-ID", ":", "Int"])
  }

  @Test("a range between two numbers is two numbers")
  func numbers() {
    #expect(words("0..<1") == ["0", ".", ".", "<", "1"])
    #expect(words("1.5e-3 + 0x1F") == ["1.5e-3", "+", "0x1F"])
    #expect(words("1_000.count") == ["1_000", ".", "count"])
  }

  @Test("a token carries the line it starts on")
  func lines() {
    let lexed = SwiftLexer.lex("a\n\n/* one\ntwo */\nb \"\"\"\n text\n \"\"\"\nc")

    #expect(lexed.tokens.map(\.line) == [1, 5, 8])
  }

  /// A scan that reads a test's title asks for the literals; every other scan is handed none, so
  /// its token stream is the one it always matched.
  @Test("a scan that keeps strings reads each literal as one token where it starts")
  func keptStrings() {
    let source = #"@Test("a \"title\"", .bug("x")) let b = "now: \(f("y")) done""#
    let kept = SwiftLexer.lex(source, keepingStrings: true).tokens

    #expect(
      kept.map(\.text) == [
        "@Test", "(", #"a \"title\""#, ",", ".", "bug", "(", "x", ")", ")", "let", "b", "=",
        #"now: \(…) done"#, "f", "(", "y", ")",
      ])
    #expect(kept.filter { $0.kind == .string }.count == 4)
    #expect(!SwiftLexer.lex(source).tokens.contains { $0.kind == .string })

    let multiline = SwiftLexer.lex(
      "let a = \"\"\"\n  two\n  lines\n  \"\"\"\nb", keepingStrings: true)
    #expect(multiline.tokens.map(\.text) == ["let", "a", "=", "\n  two\n  lines\n  ", "b"])
    #expect(multiline.tokens.map(\.line) == [1, 1, 1, 1, 5])
  }
}
