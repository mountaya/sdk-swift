import Testing

@testable import MountayaGeo

@Suite("clampRange")
struct ClampRangeTests {
  @Test("the narrowest window is a hundred meters")
  func minimum() {
    #expect(minRangeSpanMeters == 100)
  }

  @Test("a window is ordered and held inside the itinerary")
  func held() {
    #expect(
      clampRange(ProfileRange(from: 200, to: 800), totalDistance: 1_000)
        == ProfileRange(from: 200, to: 800))
    #expect(
      clampRange(ProfileRange(from: 800, to: 200), totalDistance: 1_000)
        == ProfileRange(from: 200, to: 800))
    #expect(
      clampRange(ProfileRange(from: -200, to: 1_500), totalDistance: 1_000)
        == ProfileRange(from: 0, to: 1_000))
    #expect(
      clampRange(ProfileRange(from: -.infinity, to: .infinity), totalDistance: 1_000)
        == ProfileRange(from: 0, to: 1_000))
  }

  @Test("a narrow window widens forward from its start, and back from the itinerary's end")
  func widened() {
    #expect(
      clampRange(ProfileRange(from: 0, to: 50), totalDistance: 1_000)
        == ProfileRange(from: 0, to: 100))
    #expect(
      clampRange(ProfileRange(from: 500, to: 550), totalDistance: 1_000)
        == ProfileRange(from: 500, to: 600))
    #expect(
      clampRange(ProfileRange(from: 980, to: 1_000), totalDistance: 1_000)
        == ProfileRange(from: 900, to: 1_000))
    #expect(
      clampRange(ProfileRange(from: 10_000, to: 10_000), totalDistance: 10_000)
        == ProfileRange(from: 9_900, to: 10_000))
  }

  @Test("an end that is no number reads as the itinerary's end on that side")
  func noNumber() {
    #expect(
      clampRange(ProfileRange(from: .nan, to: 500), totalDistance: 1_000)
        == ProfileRange(from: 0, to: 500))
    #expect(
      clampRange(ProfileRange(from: 200, to: .nan), totalDistance: 1_000)
        == ProfileRange(from: 200, to: 1_000))
  }

  @Test("a short itinerary is its own width, and one of no length a window of no length")
  func short() {
    #expect(
      clampRange(ProfileRange(from: 10, to: 20), totalDistance: 60) == ProfileRange(from: 0, to: 60)
    )
    #expect(
      clampRange(ProfileRange(from: 10, to: 20), totalDistance: 0) == ProfileRange(from: 0, to: 0))
    #expect(
      clampRange(ProfileRange(from: 10, to: 20), totalDistance: .nan)
        == ProfileRange(from: 0, to: 0))
    #expect(
      clampRange(ProfileRange(from: 10, to: 20), totalDistance: -5) == ProfileRange(from: 0, to: 0))
  }
}
