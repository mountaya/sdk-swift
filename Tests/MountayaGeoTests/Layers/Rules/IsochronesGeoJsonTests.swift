import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("isochronesGeoJson")
struct IsochronesGeoJsonTests {
  private let square = GeoJSONGeometry.polygon(
    GeoJSONPolygon(coordinates: [[[0, 0], [1, 0], [1, 1], [0, 0]]]))

  @Test("each band is a polygon coloured by its place")
  func bands() throws {
    let bands = DataSchema.IsochronesResult {
      $0.isochrones = (0..<7).map { index in
        DataSchema.Isochrone {
          $0.value = 600 * Double(index + 1)
          $0.geometry = square
        }
      }
    }
    let features = isochronesGeoJson(bands).features
    #expect(features.count == 7)
    let first = try #require(features.first)
    let last = try #require(features.last)
    #expect(first.geometry == square)
    #expect(first.properties[featureColorProperty] == "#c5f6fa")
    // Past the last stop the ramp starts again from the first.
    #expect(last.properties[featureColorProperty] == "#c5f6fa")
    #expect(last.properties[featureIndexProperty] == 6)
    #expect(first.properties["area"] == .null)
    #expect(first.properties["value"] == 600)
    #expect(
      Set(first.properties.keys)
        == ["area", "center", "reachFactor", "value", "mtyaColor", "mtyaIndex", "mtyaKind"])
    #expect(first.properties[featureKindProperty] == "isochrone")
  }

  @Test("an answer with no band draws nothing")
  func none() {
    #expect(isochronesGeoJson(DataSchema.IsochronesResult()).features.isEmpty)
  }

  @Test("a band takes the ramp's colour at its place, the ramp taken again past its last stop")
  func color() {
    #expect(
      isochroneRamp == ["#c5f6fa", "#99e9f2", "#66d9e8", "#3bc9db", "#22b8cf", "#15aabf"])
    #expect((0..<6).map(isochroneColor) == isochroneRamp)
    #expect(isochroneColor(6) == "#c5f6fa")
    #expect(isochroneColor(8) == "#66d9e8")
    #expect(isochroneColor(13) == "#99e9f2")
    // 2^63 - 1 is 1 past a multiple of 6.
    #expect(isochroneColor(Int.max) == "#99e9f2")
  }

  /// An index below zero is no place in an answer, and takes the first stop rather than reading the
  /// ramp back from its last.
  @Test("an index below zero takes the first stop")
  func belowZero() {
    #expect(isochroneColor(-1) == "#c5f6fa")
    #expect(isochroneColor(-6) == "#c5f6fa")
    #expect(isochroneColor(-7) == "#c5f6fa")
    #expect(isochroneColor(Int.min) == "#c5f6fa")
  }
}
