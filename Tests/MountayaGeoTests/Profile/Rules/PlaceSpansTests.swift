import Testing

@testable import MountayaGeo

@Suite("placeSpans")
struct PlaceSpansTests {
  @Test("a stretch the window does not reach, or only touches, is left out")
  func outside() {
    let window = ProfileRange(from: 5_000, to: 10_000)
    let placed = placeSpans(
      [ProfileRange(from: 0, to: 4_000), ProfileRange(from: 4_000, to: 10_000)],
      totalDistance: 10_000, window: window)
    #expect(placed.map(\.index) == [1] && placed.first?.start == 0 && placed.first?.end == 100)
    #expect(placed.first?.from == 4_000 && placed.first?.to == 10_000)
    let touching = placeSpans(
      [ProfileRange(from: 0, to: 5_000), ProfileRange(from: 6_000, to: 8_000)],
      totalDistance: 10_000, window: window)
    #expect(
      touching.map(\.index) == [1] && touching.first?.start == 20 && touching.first?.end == 60)
  }

  @Test("a stretch of no length is left out, one given backwards read in order, the order kept")
  func ordered() {
    let placed = placeSpans(
      [
        ProfileRange(from: 3_000, to: 3_000), ProfileRange(from: 7_500, to: 2_500),
        ProfileRange(from: 1_000, to: 2_000),
      ], totalDistance: 10_000)
    #expect(placed.map(\.index) == [1, 2])
    #expect(placed.first?.from == 2_500 && placed.first?.to == 7_500)
    #expect(placed.first?.start == 25 && placed.first?.end == 75)
  }

  @Test("with no window the chart is the whole itinerary, a stretch past it left out")
  func whole() {
    let placed = placeSpans(
      [ProfileRange(from: 0, to: 2_500), ProfileRange(from: 10_000, to: 12_000)],
      totalDistance: 10_000)
    #expect(placed.map(\.index) == [0])
  }

  @Test("a window given backwards is read in order, and a stretch keeps its own members")
  func backwards() {
    let placed = placeSpans(
      [ProfileClass(from: 4_000, to: 6_000, color: "#f00", label: "Path")], totalDistance: 10_000,
      window: ProfileRange(from: 8_000, to: 2_000))
    #expect(placed.first?.start == 33.333 && placed.first?.end == 66.667)
    #expect(placed.first?.span.label == "Path")
  }
}
