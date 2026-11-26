import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchLimit")
struct SearchLimitTests {
  @Test("a cap is a whole number from 1 to the ceiling, and any other is no cap")
  func range() {
    #expect(SearchLimit(1)?.value == 1)
    #expect(SearchLimit(50)?.value == 50)
    #expect(SearchLimit(searchLimitMax)?.value == 50)
    #expect(SearchLimit(0) == nil)
    #expect(SearchLimit(51) == nil)
    #expect(SearchLimit(-1) == nil)
    #expect(SearchLimit(.max) == nil)
    #expect(SearchLimit(5) == SearchLimit(5))
  }
}
