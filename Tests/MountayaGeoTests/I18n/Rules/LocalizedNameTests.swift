import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("localizedName")
struct LocalizedNameTests {
  private func rest(en: String? = nil, fr: String? = nil, de: String? = nil) -> RestSchema.Locales {
    RestSchema.Locales(
      de: de.map { ["name": $0] }, en: en.map { ["name": $0] }, es: nil,
      fr: fr.map { ["name": $0] }, it: nil, ja: nil, zh: nil)
  }

  @Test("an entry is named in its language, then in English, then by its slug")
  func order() {
    #expect(
      localizedName(
        locales: rest(en: "Snow depth", fr: "Hauteur de neige"), slug: "snow-depth", language: "fr")
        == "Hauteur de neige")
    #expect(
      localizedName(locales: rest(en: "Snow depth"), slug: "snow-depth", language: "fr")
        == "Snow depth")
    #expect(localizedName(locales: rest(), slug: "snow-depth", language: "fr") == "snow-depth")
  }

  /// The language is read by its primary subtag, as a label language is.
  @Test("the language is read by its primary subtag")
  func primarySubtag() {
    let locales = rest(en: "Snow depth", fr: "Hauteur de neige", de: "Schneeh\u{F6}he")
    #expect(
      localizedName(locales: locales, slug: "snow-depth", language: "fr-CA") == "Hauteur de neige")
    #expect(
      localizedName(locales: locales, slug: "snow-depth", language: "FR") == "Hauteur de neige")
    #expect(
      localizedName(locales: locales, slug: "snow-depth", language: "de_CH") == "Schneeh\u{F6}he")
    #expect(localizedName(locales: locales, slug: "snow-depth", language: "frr") == "Snow depth")
    #expect(localizedName(locales: locales, slug: "snow-depth", language: "pt") == "Snow depth")
    #expect(localizedName(locales: locales, slug: "snow-depth", language: nil) == "Snow depth")
  }

  /// An empty name falls through as a missing one does; one of white space is a name.
  @Test("an empty name falls through, and one of white space is a name")
  func empty() {
    #expect(
      localizedName(locales: rest(en: "Snow depth", fr: ""), slug: "snow-depth", language: "fr")
        == "Snow depth")
    #expect(
      localizedName(locales: rest(en: ""), slug: "snow-depth", language: "de") == "snow-depth")
    #expect(
      localizedName(locales: rest(en: "Snow depth", fr: " "), slug: "snow-depth", language: "fr")
        == " ")
  }

  @Test("the Tile API's entries are named the same way")
  func tile() {
    let locales = TileSchema.Locales(
      de: nil, en: ["name": "Snow depth"], es: nil, fr: ["name": nil], it: nil, ja: nil, zh: nil)
    #expect(localizedName(locales: locales, slug: "snow-depth", language: "fr") == "Snow depth")
    #expect(localizedName(locales: locales, slug: "snow-depth", language: "ja") == "Snow depth")
  }
}
