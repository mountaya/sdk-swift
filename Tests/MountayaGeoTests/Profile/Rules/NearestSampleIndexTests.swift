import Testing

@testable import MountayaGeo

@Suite("nearestSampleIndex")
struct NearestSampleIndexTests {
  private let points = samples((0, 1_000), (1, 1_000), (240, 1_100))

  @Test("the nearest sample is found, the earlier taking a tie")
  func nearest() {
    #expect(nearestSampleIndex(points, distance: 0.4) == 0)
    #expect(nearestSampleIndex(points, distance: 0.5) == 0)
    #expect(nearestSampleIndex(points, distance: 120.5) == 1)
    #expect(nearestSampleIndex(points, distance: 121) == 2)
  }

  @Test("a distance before or past the samples reads that end, and no sample reads none")
  func ends() {
    #expect(nearestSampleIndex(points, distance: -50) == 0)
    #expect(nearestSampleIndex(points, distance: 5_000) == 2)
    #expect(nearestSampleIndex(points, distance: .nan) == 0)
    #expect(nearestSampleIndex([], distance: 0) == nil)
  }
}
