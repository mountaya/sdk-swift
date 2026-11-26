import Testing

@testable import MountayaGeo

@Suite("highlightRanges")
struct HighlightRangesTests {
  /// The runs `query` matches in `title`, as the UTF-16 offsets Kotlin answers.
  private func runs(_ title: String, query: String) -> [Range<Int>] {
    utf16(highlightRanges(title, query: query), in: title)
  }

  @Test("a query matches without regard to case or accents")
  func caseAndAccents() {
    #expect(runs("MONT blanc", query: "mont") == [0..<4])
    #expect(runs("\u{C9}vian-les-Bains", query: "evian") == [0..<5])
    #expect(runs("Geneve", query: "GEN\u{C8}VE") == [0..<6])
    #expect(runs("E\u{301}vian", query: "evian") == [0..<6])
  }

  @Test("every match is found left to right and never overlapping")
  func leftToRight() {
    #expect(runs("Col de la Croix de Fer", query: "de") == [4..<6, 16..<18])
    #expect(runs("aaaa", query: "aa") == [0..<2, 2..<4])
  }

  /// The emphasis never moves with a fold that changes a length, and a run takes a segment whole.
  @Test("a run is made of whole segments of the title as written")
  func wholeSegments() {
    #expect(runs("\u{130}stanbul", query: "stan") == [1..<5])
    #expect(runs("Stra\u{DF}e", query: "stras") == [0..<5])
    #expect(runs("Bahnhofstra\u{DF}e", query: "strasse") == [7..<13])
    #expect(runs("Hauptstrasse", query: "stra\u{DF}e") == [5..<12])
    // Both halves of a sharp s's fold are one run of the one letter.
    #expect(runs("Stra\u{DF}e", query: "s").dropFirst() == [4..<5])
    // A consonant matched with the vowel sign on it, never alone.
    #expect(runs("\u{915}\u{93F}\u{932}\u{93E}", query: "\u{915}") == [0..<2])
  }

  @Test("a stroke letter matches the plain letter on either side")
  func strokes() {
    #expect(runs("\u{141}\u{F3}d\u{17A}", query: "lodz") == [0..<4])
    #expect(runs("Tromso", query: "troms\u{F8}") == [0..<6])
    #expect(runs("\u{110}\u{E0} N\u{1EB5}ng", query: "da nang") == [0..<7])
  }

  @Test("no run where either side is empty or the query folds to nothing")
  func none() {
    #expect(runs("Chamonix", query: "").isEmpty)
    #expect(runs("", query: "mont").isEmpty)
    #expect(runs("Chamonix", query: "\u{301}").isEmpty)
    #expect(runs("Chamonix", query: "zermatt").isEmpty)
  }

  /// A run may end between the two regional indicators of a flag, inside one `Character`; it is
  /// read through the title's scalars, so the bound stays where it falls.
  @Test("a run may end inside a Character")
  func insideCharacter() throws {
    let title = "\u{1F1EB}\u{1F1F7}"
    let ranges = highlightRanges(title, query: "\u{1F1EB}")
    #expect(utf16(ranges, in: title) == [0..<2])
    let run = try #require(ranges.first)
    #expect(scalars(String(title.unicodeScalars[run])) == [0x1F1EB])
  }

  /// A round folds its query once and matches every row's title against that fold.
  @Test("a title matched against a query folded once answers what the query answers")
  func foldedOnce() {
    let titles = [
      "MONT blanc", "\u{C9}vian-les-Bains", "E\u{301}vian", "Col de la Croix de Fer", "aaaa",
      "\u{130}stanbul", "Bahnhofstra\u{DF}e", "\u{141}\u{F3}d\u{17A}", "\u{1F1EB}\u{1F1F7}", "",
      "\u{915}\u{93F}\u{932}\u{93E}", "\u{1100}\u{1161}\u{11A8}",
    ]
    let queries = [
      "mont", "evian", "de", "aa", "stan", "strasse", "lodz", "\u{1F1EB}", "", "\u{301}",
      "\u{915}", "\u{AC01}",
    ]
    for query in queries {
      let folded = foldedQuery(query)
      for title in titles {
        #expect(
          highlightRanges(title, folded: folded) == highlightRanges(title, query: query),
          "\(title) for \(query)")
      }
    }
    #expect(foldedQuery("").isEmpty)
    #expect(foldedQuery("\u{301}").isEmpty, "a lone accent folds to nothing")
    #expect(foldedQuery("GEN\u{C8}VE") == Array("geneve".unicodeScalars))
  }
}
