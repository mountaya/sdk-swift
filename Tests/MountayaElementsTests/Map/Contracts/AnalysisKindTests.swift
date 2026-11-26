import Testing

@testable import MountayaElements

@Suite("AnalysisKind")
struct AnalysisKindTests {
  @Test("each kind of result is named as the contract's fixtures name it")
  func names() {
    #expect(
      AnalysisKind.allCases.map(\.rawValue) == [
        "directions", "suggestions", "isochrones", "places", "matrix", "pois",
      ])
    #expect(AnalysisKind(rawValue: "geocode") == nil, "a place is a result of kind `places`")
  }
}
