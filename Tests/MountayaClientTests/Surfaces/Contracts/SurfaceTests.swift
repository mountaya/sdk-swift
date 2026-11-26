import Testing

@testable import MountayaClient

@Suite("Surface")
struct SurfaceTests {
  @Test("each surface is named as the contract names it, and the facts speak the same type")
  func names() {
    #expect(Surface.allCases.map(\.rawValue) == ["rest", "tiles", "data"])
    #expect(OperationFacts.getItinerary.surface == Surface.rest)
  }
}
