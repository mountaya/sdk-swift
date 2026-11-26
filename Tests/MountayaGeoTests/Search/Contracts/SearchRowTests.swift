import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchRow")
struct SearchRowTests {
  private func row(_ title: String) -> SearchRow {
    SearchRow(
      id: "zone:z", title: title,
      matched: [title.startIndex..<title.index(after: title.startIndex)],
      secondary: .text("x"), activities: [], payload: .zone(zoneId: "z", point: nil, bounds: nil))
  }

  @Test("two rows are equal where every member is, and a row is identified by its id")
  func equality() {
    #expect(row("Zone") == row("Zone"))
    #expect(row("Zone").hashValue == row("Zone").hashValue)
    #expect(row("Zone") != row("Other"))
    #expect(row("Zone").id == "zone:z")
  }

  @Test("two rows are told apart by the scalars of their texts and activities")
  func scalars() {
    #expect(row("\u{E9}") == row("\u{E9}"))
    #expect(row("\u{E9}") != row("e\u{301}"))
    var spelled = row("Zone")
    spelled.id = "zone:\u{E9}"
    var decomposed = row("Zone")
    decomposed.id = "zone:e\u{301}"
    #expect(spelled != decomposed)
    var hiking = row("Zone")
    hiking.activities = [DataSchema.ActivitySlug(rawValue: "\u{E9}")]
    var other = row("Zone")
    other.activities = [DataSchema.ActivitySlug(rawValue: "e\u{301}")]
    #expect(hiking != other)
    #expect(hiking.hashValue == hiking.hashValue)
  }

  @Test("a row's parts are its title cut at the runs it matched, as highlightParts cuts them")
  func parts() throws {
    let built = try #require(
      placeRow(SearchEntities.place(name: "Col du Galibier"), query: "gali"))
    #expect(
      built.parts == [
        HighlightPart(text: "Col du ", match: false), HighlightPart(text: "Gali", match: true),
        HighlightPart(text: "bier", match: false),
      ])
    for (title, query) in [
      ("\u{130}stanbul", "stan"), ("Stra\u{DF}e", "stras"), ("Pre\u{301} Saint-Didier", "pre"),
      ("\u{1F1EB}\u{1F1F7} Paris", "\u{1F1EB}"), ("Chamonix", "zermatt"), ("", "mont"),
    ] {
      let row = SearchRow(
        id: "zone:z", title: title, matched: highlightRanges(title, query: query), secondary: nil,
        activities: [], payload: .zone(zoneId: "z", point: nil, bounds: nil))
      #expect(row.parts == highlightParts(title, query: query), "\(title)")
      #expect(
        Array(row.parts.map(\.text).joined().unicodeScalars) == Array(title.unicodeScalars),
        "\(title)")
    }
  }

  /// A row is a value a host may write by hand, so its runs are read with care.
  @Test("a run out of order or past the title is left unmatched, and the title drawn whole")
  func partsOfAHandWrittenRow() {
    let title = "Mont Blanc"
    let other = "Mont Blanc du Tacul"
    var row = row(title)
    let blanc = title.index(title.startIndex, offsetBy: 5)..<title.endIndex
    let mont = title.startIndex..<title.index(title.startIndex, offsetBy: 4)

    row.matched = [blanc, mont]
    #expect(
      row.parts == [
        HighlightPart(text: "Mont ", match: false), HighlightPart(text: "Blanc", match: true),
      ], "a run that starts before the one ahead of it ends is passed over")
    row.matched = [mont, other.startIndex..<other.endIndex]
    #expect(
      row.parts == [
        HighlightPart(text: "Mont", match: true), HighlightPart(text: " Blanc", match: false),
      ], "a run past the title is passed over")
    row.matched = [other.index(other.startIndex, offsetBy: 12)..<other.endIndex]
    #expect(row.parts == [HighlightPart(text: title, match: false)])
    row.matched = []
    #expect(row.parts == [HighlightPart(text: title, match: false)])
  }
}
