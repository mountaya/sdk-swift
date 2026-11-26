import Foundation
import Testing

@testable import MountayaGeo

@Suite("platformLocale")
struct PlatformLocaleTests {
  @Test("a tag's language, region, calendar and numbering system are the locale's")
  func components() {
    let locale = platformLocale("th-TH-u-ca-gregory")
    #expect(locale.language.languageCode?.identifier == "th")
    #expect(locale.region?.identifier == "TH")
    #expect(locale.calendar.identifier == .gregorian)
    #expect(platformLocale("fr_FR").region?.identifier == "FR")
  }

  /// `Locale(identifier:)` on macOS 27 reads a `nu` value equal to the language's script code as
  /// that script and drops it, `bn-BD-u-nu-beng` leaving `bn-BD-u-nu`; `en-US-u-nu-arab` it keeps.
  @Test("a numbering system named as the language's script is kept")
  func namedAsTheScript() {
    #expect(platformLocale("bn-BD-u-nu-beng").numberingSystem.identifier == "beng")
    #expect(platformLocale("th-TH-u-nu-thai").numberingSystem.identifier == "thai")
    #expect(platformLocale("hi-IN-u-nu-deva").numberingSystem.identifier == "deva")
    #expect(platformLocale("ar-EG-u-nu-arab").numberingSystem.identifier == "arab")
    #expect(platformLocale("en-US-u-nu-latn").numberingSystem.identifier == "latn")
    #expect(platformLocale("en-US-u-nu-arab").numberingSystem.identifier == "arab")
  }

  @Test("a numbering system the platform does not carry is dropped")
  func unknownSystem() {
    #expect(platformLocale("en-u-nu-xxxx").numberingSystem.identifier == "latn")
  }

  @Test("a tag read again answers the locale its first reading parsed")
  func cachedAnswersParsed() {
    let tags = [
      "th-TH-u-ca-gregory", "bn-BD-u-nu-beng", "en-u-nu-xxxx", "fr_FR", "de-CH", "fa-IR", "",
    ]
    for tag in tags {
      let parsed = parsedLocale(tag)
      for _ in 0..<3 {
        let read = platformLocale(tag)
        #expect(read == parsed, "\(tag)")
        #expect(read.identifier == parsed.identifier, "\(tag)")
        #expect(read.numberingSystem == parsed.numberingSystem, "\(tag)")
      }
    }
  }

  /// A cache of the test's own, so the count reads this test's parses alone.
  @Test("a tag is parsed once, and a full cache is emptied before it keeps the next")
  func parsedOnce() {
    let cache = Locked<[String: Locale]>([:])
    var parses: [String] = []
    func read(_ tag: String) -> Locale {
      cachedLocale(tag, in: cache, limit: 2) { tag in
        parses.append(tag)
        return parsedLocale(tag)
      }
    }

    #expect(read("fr-FR") == parsedLocale("fr-FR"))
    #expect(read("fr-FR") == parsedLocale("fr-FR"))
    #expect(read("de-DE") == parsedLocale("de-DE"))
    #expect(parses == ["fr-FR", "de-DE"], "each tag is parsed once while the cache holds it")

    #expect(read("it-IT") == parsedLocale("it-IT"))
    #expect(cache.value.keys.sorted() == ["it-IT"], "the full cache was emptied first")
    #expect(read("fr-FR") == parsedLocale("fr-FR"))
    #expect(parses == ["fr-FR", "de-DE", "it-IT", "fr-FR"])
  }

  /// Each tag traps `DateFormatter` on Linux when it is read through `Locale(identifier:)`, and
  /// writes nothing on Apple platforms; read through the seam, every host writes it.
  @Test("a tag the platform's own reading breaks writes its date and its number")
  func writesEverywhere() {
    let piDay = Date(timeIntervalSince1970: 1_773_446_400)
    #expect(
      localeDateText(
        piDay, languageTag: "bn-BD-u-nu-beng", timeZone: "UTC", dateLength: .long, timeLength: nil)
        == "১৪ মার্চ, ২০২৬")
    #expect(
      localeDateText(
        piDay, languageTag: "en-u-nu-xxxx", timeZone: "UTC", dateLength: .long, timeLength: nil)
        == "March 14, 2026")
    #expect(
      localeNumberText(1_531, languageTag: "bn-BD-u-nu-beng", fractionDigits: 0, grouping: true)
        == "১,৫৩১")
    #expect(
      localeNumberText(1_531, languageTag: "en-u-nu-xxxx", fractionDigits: 0, grouping: true)
        == "1,531")
  }
}
