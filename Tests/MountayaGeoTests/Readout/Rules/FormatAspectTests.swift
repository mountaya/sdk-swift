import Testing

@testable import MountayaGeo

@Suite("formatAspect")
struct FormatAspectTests {
  @Test("the bearing in whole degrees beside its direction's word")
  func written() {
    #expect(formatAspect(123.4, cardinalWord: "South-East", language: "en") == "123° · South-East")
    #expect(formatAspect(236.6, cardinalWord: "Sud-ouest", language: "fr") == "237° · Sud-ouest")
  }

  @Test("the bearing alone with no word, and nothing for no number")
  func partial() {
    #expect(formatAspect(90, cardinalWord: "", language: "en") == "90°")
    #expect(formatAspect(.nan, cardinalWord: "East", language: "en") == "")
  }
}
