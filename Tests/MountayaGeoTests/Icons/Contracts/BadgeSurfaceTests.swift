import Testing

@testable import MountayaGeo

@Suite("BadgeSurface")
struct BadgeSurfaceTests {
  @Test("a badge stands in a table's cell, in a profile's stack, or beside a label of its own")
  func surfaces() {
    #expect(BadgeSurface.allCases.map(\.rawValue) == ["cell", "stack", "labelled"])
    #expect(BadgeSurface.allCases.map { badgeFallback("Water", on: $0) } == ["Water", "W", nil])
  }
}
