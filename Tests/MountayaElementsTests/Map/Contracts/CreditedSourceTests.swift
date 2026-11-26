import Testing

@testable import MountayaElements

@Suite("CreditedSource")
struct CreditedSourceTests {
  @Test("a source is its credit, which may be absent, and whether a layer draws it")
  func source() {
    #expect(
      CreditedSource(attribution: nil, isDrawn: true)
        != CreditedSource(attribution: "", isDrawn: true))
    #expect(
      CreditedSource(attribution: "a", isDrawn: false)
        != CreditedSource(attribution: "a", isDrawn: true))
  }
}
