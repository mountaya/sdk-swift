import Testing

@testable import MountayaGeo

@Suite("rangePatterns")
struct RangePatternsTests {
  @Test("the seven languages hold CLDR's range and approximately patterns, any other English's")
  func table() {
    #expect(rangePatternLanguages == unitPatternLanguages)
    #expect(rangePatterns("en") == RangePatterns(range: "{0}\u{2013}{1}", approximately: "~{0}"))
    #expect(rangePatterns("fr-CA").approximately == "\u{2243}{0}")
    #expect(rangePatterns("de").approximately == "\u{2248}{0}")
    #expect(rangePatterns("es").range == "{0}-{1}" && rangePatterns("it").range == "{0}-{1}")
    #expect(
      rangePatterns("ja") == RangePatterns(range: "{0}\u{FF5E}{1}", approximately: "\u{7D04}{0}"))
    #expect(rangePatterns("zh").range == "{0}-{1}")
    #expect(rangePatterns("pt") == rangePatterns("en"))
  }
}
