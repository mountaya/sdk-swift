import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("WordBundle")
struct WordBundleTests {
  @Test("two bundles are equal where they hold the same words, and hash alike")
  func equality() {
    let title: [String: JSONValue] = ["title": "Map"]
    #expect(WordBundle(english: title) == WordBundle(english: ["title": "Map"]))
    #expect(WordBundle(english: title).hashValue == WordBundle(english: ["title": "Map"]).hashValue)
    #expect(WordBundle(english: title) != WordBundle(english: [:]))
    #expect(
      WordBundle(english: title, translations: [.fr: ["title": "Carte"]])
        != WordBundle(english: title, partial: [.fr: ["title": "Carte"]]))
  }

  /// A word is compared by its scalars, as the other SDKs compare it, never by canonical
  /// equivalence.
  @Test("two words are the same where they are written with the same scalars")
  func scalars() {
    #expect(
      WordBundle(english: ["title": "Caf\u{E9}"]) != WordBundle(english: ["title": "Cafe\u{301}"]))
  }
}
