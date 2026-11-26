import Testing

@testable import MountayaGeo

@Suite("ElevationPoint")
struct ElevationPointTests {
  private let sample = ElevationPoint(
    distance: 952.5, elevation: 1_120, lngLat: [6.8752, 45.9287], index: 1)

  @Test("two samples are equal when they hold the same numbers, and hash alike")
  func equality() {
    let same = ElevationPoint(
      distance: 952.5, elevation: 1_120, lngLat: [6.8752, 45.9287], index: 1)
    #expect(sample == same)
    #expect(sample.hashValue == same.hashValue)
    #expect(
      sample
        != ElevationPoint(distance: 952.5, elevation: 1_120, lngLat: [6.8752, 45.9287], index: 2))
    #expect(
      ElevationPoint(distance: 0, elevation: 0, lngLat: [0, 0], index: 0)
        != ElevationPoint(distance: -0.0, elevation: 0, lngLat: [0, 0], index: 0))
    #expect(
      ElevationPoint(distance: .nan, elevation: 0, lngLat: [0, 0], index: 0)
        == ElevationPoint(distance: .nan, elevation: 0, lngLat: [0, 0], index: 0))
  }

  @Test("each figure is named by what it holds")
  func description() {
    #expect(
      String(describing: sample)
        == "ElevationPoint(distance: 952.5, elevation: 1120.0, lngLat: [6.8752, 45.9287], index: 1)"
    )
  }
}
