import MountayaElements
import Testing

@Suite("AnalysisHandle")
struct AnalysisHandleTests {
  @Test("a handle carries the id a result is drawn under and the result, equal where both are")
  func carries() {
    let handle = AnalysisHandle(id: "analysis:isochrones:0", result: 3)

    #expect(handle.id == "analysis:isochrones:0")
    #expect(handle.result == 3)
    #expect(handle == AnalysisHandle(id: "analysis:isochrones:0", result: 3))
    #expect(handle != AnalysisHandle(id: "analysis:isochrones:1", result: 3))
    #expect(handle != AnalysisHandle(id: "analysis:isochrones:0", result: 4))
  }
}
