import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("profileLength")
struct ProfileLengthTests {
  @Test("a geometry's length is what its series walks, jumps costing nothing")
  func length() {
    let two: GeoJSONGeometry = .multiLineString(
      GeoJSONMultiLineString(coordinates: [
        [[6, 45], [6, 45.005]], [[7, 46], [7, 46.005, 1_000]],
      ]))
    #expect(isClose(profileLength(two), buildElevationSeries(two).totalDistance, within: 1e-9))
    #expect(isClose(profileLength(two), 2 * 555.9746332230782, within: 1e-6))
    #expect(profileLength(nil) == 0)
    #expect(profileLength(.point(GeoJSONPoint(coordinates: [6, 45]))) == 0)
  }
}
