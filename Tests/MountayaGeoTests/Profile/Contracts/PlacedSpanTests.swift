import Testing

@testable import MountayaGeo

@Suite("PlacedSpan")
struct PlacedSpanTests {
  @Test("two placed stretches are equal where the stretch, its place and its numbers are")
  func equality() {
    let span = ProfileRange(from: 4_000, to: 10_000)
    let placed = PlacedSpan(span: span, index: 1, from: 4_000, to: 10_000, start: 0, end: 100)
    #expect(placed == PlacedSpan(span: span, index: 1, from: 4_000, to: 10_000, start: 0, end: 100))
    #expect(
      placed.hashValue
        == PlacedSpan(span: span, index: 1, from: 4_000, to: 10_000, start: 0, end: 100).hashValue)
    #expect(placed != PlacedSpan(span: span, index: 0, from: 4_000, to: 10_000, start: 0, end: 100))
  }
}
