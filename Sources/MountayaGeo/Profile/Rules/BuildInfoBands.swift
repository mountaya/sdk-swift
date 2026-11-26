import MountayaClient

/// The meters in a kilometer.
private let metersPerKilometer: Double = 1_000

/// buildInfoBands places the analysis entries `ranges` reads off each segment, in chain order, on
/// the itinerary's distance axis in kilometers, so each band stands under the points it colours.
///
/// Each segment's lines are laid end to end and walked as the elevation series walks them:
/// distance accumulates within a line, the jump to the next line or the next segment costs none,
/// and a vertex that names no place keeps its index and stands at the distance of the last vertex
/// that did. An index resolves to the distance at that vertex, one past the line to its last vertex
/// and one under zero to its first. A band of no length is dropped, and a band that carries its
/// predecessor's value and starts where it ends or before is merged into it. Every segment
/// advances the axis by the length of its lines, whether or not it yields a band, and one with
/// fewer than two vertices yields none.
///
/// `ranges` picks one analysis, as `{ $0.surface_info?.map { InfoRange(fromIndex: $0.from_index,
/// toIndex: $0.to_index, value: $0.value) } }` does; nil reads as none. Two values are the same
/// value by their `==`, and two numbers by the same-number relation.
public func buildInfoBands<Value: Equatable>(
  _ segments: [RestSchema.ItinerarySegment],
  ranges: (RestSchema.ItinerarySegment) -> [InfoRange<Value>]?
) -> [InfoBand<Value>] {
  var bands: [InfoBand<Value>] = []
  var itineraryKm: Double = 0
  for segment in segments {
    // The distance at each vertex of the segment's lines laid end to end, the array its indexes
    // address.
    var vertexKm: [Double] = []
    var segmentKm: Double = 0
    for line in linesOf(segment.geojson) {
      segmentKm = walkLine(line, from: segmentKm, legLength: haversineKilometers) { km, _, _ in
        vertexKm.append(km)
      }
    }
    let lastIndex = vertexKm.count - 1
    if lastIndex >= 1 {
      for range in ranges(segment) ?? [] {
        let startKm = itineraryKm + vertexKm[min(max(range.fromIndex, 0), lastIndex)]
        let endKm = itineraryKm + vertexKm[min(max(range.toIndex, 0), lastIndex)]
        guard endKm - startKm > 0 else { continue }
        if let previous = bands.last, sameValue(previous.value, range.value),
          previous.endKm >= startKm
        {
          bands[bands.count - 1] = InfoBand(
            startKm: previous.startKm, endKm: endKm, value: previous.value)
          continue
        }
        bands.append(InfoBand(startKm: startKm, endKm: endKm, value: range.value))
      }
    }
    itineraryKm += segmentKm
  }
  return bands
}

/// The great-circle distance between two positions, in kilometers.
private func haversineKilometers(_ from: [Double], _ to: [Double]) -> Double {
  haversineMeters(from: from, to: to) / metersPerKilometer
}
