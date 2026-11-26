import Testing

@testable import MountayaGeo

@Suite("committedPace")
struct CommittedPaceTests {
  @Test("the pace is the total distance over the total duration")
  func total() {
    #expect(
      committedPace([
        restSegment(distance: 10_000, duration: 3_600),
        restSegment(distance: 5_000, duration: 3_600),
      ]) == 7.5)
    // 10 km in 1.5 h, not the mean of 9 km/h and 2 km/h.
    #expect(
      committedPace([
        restSegment(distance: 9_000, duration: 3_600),
        restSegment(distance: 1_000, duration: 1_800),
      ]) == 6.666666666666667)
  }

  @Test("a segment with no timing, or no usable figure, is left out")
  func leftOut() {
    let segments = [
      restSegment(distance: 10_000, duration: 3_600),
      restSegment(distance: 5_000),
      restSegment(duration: 1_800),
      restSegment(distance: 2_000, duration: 0),
      restSegment(distance: -5_000, duration: 3_600),
      restSegment(distance: .nan, duration: 1_800),
      restSegment(distance: 3_000, duration: .infinity),
    ]
    #expect(committedPace(segments) == 10)
    #expect(committedPace([restSegment(distance: 0, duration: 60)]) == 0)
  }

  @Test("no segment left is no pace")
  func none() {
    #expect(committedPace([]) == nil)
    #expect(committedPace([restSegment(distance: 1_000)]) == nil)
  }
}
