import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("buildInfoBands")
struct BuildInfoBandsTests {
  /// 0.01 degrees of longitude at 45.85 degrees north.
  private let step = 0.7745162686035524

  private func segment(_ geometry: GeoJSONGeometry?, surface: [(ClosedRange<Int>, String)])
    -> RestSchema.ItinerarySegment
  {
    restSegment(
      geojson: geometry,
      surface: surface.map {
        RestSchema.SurfaceInfo(
          from_index: $0.0.lowerBound, to_index: $0.0.upperBound,
          value: RestSchema.SurfaceType(rawValue: $0.1))
      })
  }

  private func line(_ longitudes: Double...) -> GeoJSONGeometry {
    .lineString(GeoJSONLineString(coordinates: longitudes.map { [$0, 45.85] }))
  }

  private func bands(_ segments: RestSchema.ItinerarySegment...) -> [InfoBand<String>] {
    buildInfoBands(segments) { segment in
      segment.surface_info?.map {
        InfoRange(fromIndex: $0.from_index, toIndex: $0.to_index, value: $0.value.rawValue)
      }
    }
  }

  private func holds(_ actual: [InfoBand<String>], expected: [(Double, Double, String)]) -> Bool {
    actual.map(\.value) == expected.map(\.2)
      && zip(actual, expected).allSatisfy {
        isClose($0.startKm, $1.0, within: 1e-9) && isClose($0.endKm, $1.1, within: 1e-9)
      }
  }

  @Test("each segment advances the axis by its lines, band or no band")
  func advances() {
    #expect(
      holds(
        bands(
          segment(line(6.86, 6.87), surface: []),
          segment(line(6.87, 6.88), surface: [(0...1, "asphalt")])),
        expected: [(step, 2 * step, "asphalt")]))
  }

  @Test("a band butting on one of the same value is merged, across segments")
  func merged() {
    #expect(
      holds(
        bands(
          segment(line(6.86, 6.87, 6.88), surface: [(0...1, "gravel"), (1...2, "gravel")]),
          segment(line(6.88, 6.89), surface: [(0...1, "gravel")])),
        expected: [(0, 3 * step, "gravel")]))
  }

  @Test("a band of no length is dropped, and an index past the line reads its last vertex")
  func droppedAndClamped() {
    #expect(
      holds(
        bands(
          segment(
            line(6.86, 6.87, 6.87, 6.88),
            surface: [(1...1, "asphalt"), (1...2, "gravel"), (2...3, "ground")])),
        expected: [(step, 2 * step, "ground")]))
    #expect(
      holds(
        bands(segment(line(6.86, 6.87), surface: [(-3...40, "asphalt")])),
        expected: [(0, step, "asphalt")]))
  }

  @Test("the lines of a MultiLineString are laid end to end")
  func multiLine() {
    let geometry = GeoJSONGeometry.multiLineString(
      GeoJSONMultiLineString(coordinates: [
        [[6.86, 45.85], [6.87, 45.85]], [[6.9, 45.85], [6.91, 45.85]],
      ]))
    #expect(
      holds(
        bands(
          segment(geometry, surface: [(0...1, "asphalt"), (1...2, "gravel"), (2...3, "ground")])),
        expected: [(0, step, "asphalt"), (step, 2 * step, "ground")]))
  }

  @Test("a segment of fewer than two vertices yields no band")
  func fewerThanTwo() {
    #expect(
      bands(
        segment(line(6.86), surface: [(0...0, "asphalt")]),
        segment(nil, surface: [(0...1, "asphalt")])
      ).isEmpty)
  }

  /// A slope is a number, and two bands of `NaN` are one value, as every number of the geo layer.
  @Test("two bands of numbers the same-number relation calls one are merged")
  func numbers() {
    let merged = buildInfoBands([segment(line(6.86, 6.87, 6.88), surface: [])]) { _ in
      [
        InfoRange(fromIndex: 0, toIndex: 1, value: Double.nan),
        InfoRange(fromIndex: 1, toIndex: 2, value: .nan),
      ]
    }
    #expect(merged.count == 1)
  }
}
