import MountayaClient

@testable import MountayaGeo

/// climbLine is a seven-vertex climb with an altitude at every vertex, the one the profile
/// fixtures and tests read: 7,117.5 m long, from 1,035 m to a summit of 1,480 m.
let climbLine: [[Double]] = [
  [6.8652, 45.9237, 1_035],
  [6.8752, 45.9287, 1_120],
  [6.8852, 45.9337, 1_118],
  [6.8952, 45.9387, 1_290],
  [6.9052, 45.9437, 1_240],
  [6.9152, 45.9487, 1_480],
  [6.9271, 45.9682, 1_252],
]

/// samples is a series' samples at the distances and altitudes a test writes, each at the origin
/// and numbered by its place.
func samples(_ pairs: (Double, Double)...) -> [ElevationPoint] {
  pairs.enumerated().map {
    ElevationPoint(
      distance: $0.element.0, elevation: $0.element.1, lngLat: [0, 0], index: $0.offset)
  }
}

/// samplesEvery100Meters is a series' samples a hundred meters apart, at the altitudes a test
/// writes.
func samplesEvery100Meters(_ elevations: Double...) -> [ElevationPoint] {
  elevations.enumerated().map {
    ElevationPoint(
      distance: Double($0.offset) * 100, elevation: $0.element, lngLat: [0, 0], index: $0.offset)
  }
}
