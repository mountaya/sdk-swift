import Testing

@testable import MountayaGeo

@Suite("curveSpans")
struct CurveSpansTests {
  @Test("stretches are read in order, the earlier of two overlapping keeping the shared ground")
  func ordered() {
    let spans = curveSpans([
      CurveColor(from: 400, to: 1_000, color: "#00f"), CurveColor(from: 600, to: 0, color: "#f00"),
    ])
    #expect(
      spans == [
        CurveColor(from: 0, to: 600, color: "#f00"),
        CurveColor(from: 600, to: 1_000, color: "#00f"),
      ])
  }

  @Test("a stretch of no length, or swallowed by an earlier one, is left out")
  func leftOut() {
    let spans = curveSpans([
      ProfileRange(from: 300, to: 300), ProfileRange(from: 0, to: 600),
      ProfileRange(from: 100, to: 500),
      ProfileRange(from: .nan, to: 10),
    ])
    #expect(spans == [ProfileRange(from: 0, to: 600)])
  }

  @Test("stretches starting at one distance keep the order given")
  func stable() {
    let spans = curveSpans([
      ProfileClass(from: 0, to: 100, color: "#f00", label: "a"),
      ProfileClass(from: 0, to: 200, color: "#00f", label: "b"),
    ])
    #expect(spans.map(\.label) == ["a", "b"])
    #expect(spans.last?.from == 100)
  }
}
