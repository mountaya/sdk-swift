import MountayaClient

/// maxProfilePoints is how many samples an elevation series holds where its caller names no other
/// ceiling, the `maxPoints` `geo/elevation-series.json` declares: a chart a few hundred pixels wide
/// shows no more, and the thinning is a uniform stride that changes the curve's resolution and not
/// its shape.
public let maxProfilePoints = 500

/// buildElevationSeries projects a geometry onto an elevation series: the great-circle distance
/// along it, in meters, against the altitude its vertices carry, their third value.
///
/// Every line the geometry holds is walked in the order it writes them and laid end to end on one
/// distance axis: a LineString is one line, each line of a MultiLineString one, a
/// GeometryCollection holds the lines of what it holds, and anything else, a directions segment's
/// vias included, is none. The jump between two lines costs no distance, since it is a seam in the
/// storage and not ground anyone covers. A vertex with no finite altitude advances the distance and
/// is no sample, so a hole in the terrain data is bridged by the curve; a vertex that names no
/// place is no sample and charges no distance, the line measured across it. No geometry is an
/// itinerary of no length.
///
/// A series of more than `maxPoints` samples is thinned by a uniform stride, keeping the first and
/// the last: slot `k` of the others keeps the sample nearest `k × (count − 1) / (maxPoints − 1)`,
/// the later of two where it stands halfway between them, a half rounding up exactly as the
/// rational reads. A ceiling under two keeps every sample, since a curve needs both its ends. The
/// altitude range and the total distance stay the whole line's.
public func buildElevationSeries(
  _ geometry: GeoJSONGeometry?, maxPoints: Int = maxProfilePoints
) -> ElevationSeries {
  var samples: [ElevationPoint] = []
  var distance: Double = 0
  var lowest: Double?
  var highest: Double?
  for line in linesOf(geometry) {
    distance = walkLine(line, from: distance, legLength: haversineMeters) { at, vertex, _ in
      guard let vertex, vertex.count > 2, vertex[2].isFinite else { return }
      let elevation = vertex[2]
      samples.append(
        ElevationPoint(
          distance: at, elevation: elevation, lngLat: [vertex[0], vertex[1]],
          index: samples.count))
      lowest = lowest.map { minimumNumber($0, elevation) } ?? elevation
      highest = highest.map { maximumNumber($0, elevation) } ?? elevation
    }
  }
  return ElevationSeries(
    points: downsampleElevation(samples, maxPoints: maxPoints), totalDistance: distance,
    minElevation: lowest, maxElevation: highest)
}
