import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("lineBetween")
struct LineBetweenTests {
  private func points(_ entries: (Double, [Double])...) -> [ElevationPoint] {
    entries.enumerated().map {
      ElevationPoint(distance: $0.element.0, elevation: 0, lngLat: $0.element.1, index: $0.offset)
    }
  }

  private func coordinates(_ geometry: GeoJSONGeometry?) -> [[Double]]? {
    guard case .lineString(let line)? = geometry else { return nil }
    return line.coordinates
  }

  private var meridian: [ElevationPoint] {
    points((0, [6, 45]), (100, [6, 45.0009]), (200, [6, 45.0018]))
  }

  @Test("a stretch starts and ends on the curve, the samples between it held")
  func between() throws {
    let line = try #require(coordinates(lineBetween(meridian, from: 50, to: 150)))
    #expect(line.count == 3 && areClose(line[0], [6, 45.00045], within: 1e-9))
    #expect(line[1] == [6, 45.0009] && areClose(line[2], [6, 45.00135], within: 1e-9))
    #expect(
      coordinates(lineBetween(meridian, from: -100, to: 300)) == [
        [6, 45], [6, 45.0009], [6, 45.0018],
      ])
    #expect(coordinates(lineBetween(meridian, from: 120, to: 180))?.count == 2)
  }

  @Test("no length, backwards, past the samples and no sample are no line")
  func none() {
    #expect(lineBetween(meridian, from: 100, to: 100) == nil)
    #expect(lineBetween(meridian, from: 150, to: 50) == nil)
    #expect(lineBetween(meridian, from: 1_000, to: 1_000) == nil)
    #expect(lineBetween([], from: 0, to: 200) == nil)
    #expect(lineBetween(meridian, from: .nan, to: 200) == nil)
  }

  @Test("where two lines meet a stretch starts on the later and ends on the earlier")
  func linesMeet() {
    let joined = points(
      (0, [6, 45]), (100, [6, 45.0009]), (100, [6.1, 45.1]), (200, [6.1, 45.1009]))
    #expect(
      coordinates(lineBetween(joined, from: 100, to: 200)) == [[6.1, 45.1], [6.1, 45.1009]])
    #expect(coordinates(lineBetween(joined, from: 0, to: 100)) == [[6, 45], [6, 45.0009]])
  }

  @Test("across the antimeridian the stretch is read the short way, within [-180, 180]")
  func antimeridian() throws {
    let across = points((0, [179.9, 0]), (100, [-179.9, 0]))
    let line = try #require(coordinates(lineBetween(across, from: 25, to: 75)))
    #expect(
      areClose(line[0], [179.95, 0], within: 1e-9) && areClose(line[1], [-179.95, 0], within: 1e-9))
    #expect(positionAt(across, distance: 50)?[0].magnitude == 180)
  }
}
