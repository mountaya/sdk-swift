import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("dataLanguageFor")
struct DataLanguageForTests {
  @Test("a tag asks the Data API in the language the map labels in for it, in capitals")
  func tags() {
    #expect(dataLanguageFor("fr-CH") == .fr)
    #expect(dataLanguageFor("de_AT") == .de)
    #expect(dataLanguageFor("zh-Hant-TW") == .zh)
    #expect(dataLanguageFor("JA") == .ja)
    #expect(dataLanguageFor("es") == .es)
    #expect(dataLanguageFor("it") == .it)
  }

  @Test("a tag naming none of the map's languages, or no tag, asks in English")
  func english() {
    #expect(dataLanguageFor("pt-BR") == .en)
    #expect(dataLanguageFor("frr") == .en)
    #expect(dataLanguageFor("") == .en)
    #expect(dataLanguageFor(nil) == .en)
    #expect(dataLanguageFor(" fr") == .en)
  }
}
