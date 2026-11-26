import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("countedText")
struct CountedTextTests {
  private static let english: JSONValue = ["one": "{count} result", "other": "{count} results"]
  private static let french: JSONValue = ["one": "{count} résultat", "other": "{count} résultats"]

  @Test("English takes the one form for one alone, French for zero and one")
  func forms() {
    #expect(countedText(Self.english, count: 1, language: .en) == "1 result")
    #expect(countedText(Self.english, count: 0, language: .en) == "0 results")
    #expect(countedText(Self.english, count: 2, language: .en) == "2 results")
    #expect(countedText(Self.english, count: -1, language: .en) == "-1 results")
    #expect(countedText(Self.french, count: 0, language: .fr) == "0 résultat")
    #expect(countedText(Self.french, count: 1, language: .fr) == "1 résultat")
    #expect(countedText(Self.french, count: 2, language: .fr) == "2 résultats")
    #expect(countedText(Self.french, count: -1, language: .fr) == "-1 résultats")
  }

  @Test("the count is written as the words' language writes a number")
  func count() {
    #expect(countedText(Self.english, count: 1234, language: .en) == "1,234 results")
    #expect(
      countedText(Self.french, count: 1234, language: .fr) == "1\u{202F}234 résultats")
    #expect(
      countedText(Self.english, count: 1_234_567, language: .en) == "1,234,567 results")
  }

  @Test("a language the table does not hold takes the one form for one, as English does")
  func otherLanguages() {
    let german: JSONValue = ["one": "{count} Ergebnis", "other": "{count} Ergebnisse"]

    #expect(countedText(german, count: 1, language: .de) == "1 Ergebnis")
    #expect(countedText(german, count: 0, language: .de) == "0 Ergebnisse")
    #expect(countedText(german, count: 1234, language: .de) == "1.234 Ergebnisse")
    #expect(countedText(["other": "{count}件"], count: 1, language: .ja) == "1件")
  }

  @Test("a form the word does not state is its other form, and the first count placeholder fills")
  func placeholders() {
    #expect(countedText(["other": "{count} items"], count: 1, language: .en) == "1 items")
    #expect(
      countedText(["one": 1, "other": "{count} items"], count: 1, language: .en)
        == "1 items")
    #expect(countedText(["other": "none"], count: 3, language: .en) == "none")
    #expect(
      countedText(["other": "{count} of {count}"], count: 3, language: .en)
        == "3 of {count}")
    #expect(
      countedText(["other": "{Count} {count}"], count: 3, language: .en) == "{Count} 3")
    #expect(
      countedText(["other": "{total} {count}"], count: 3, language: .en) == "{total} 3")
  }

  @Test("a word that is no counted word is the refusal")
  func refused() {
    #expect(countedText("{count} results", count: 1, language: .en) == nil)
    #expect(countedText(["one": "{count} result"], count: 1, language: .en) == nil)
    #expect(countedText(["other": 3], count: 1, language: .en) == nil)
    #expect(countedText(.null, count: 1, language: .en) == nil)
  }
}
