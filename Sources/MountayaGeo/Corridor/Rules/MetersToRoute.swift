import MountayaClient

/// metersToRoute is the shortest distance in meters from a point to any segment of any of a list
/// of lines, the measure a corridor around an itinerary is tested by.
///
/// Each segment is projected into a local plane centred on the point, a degree of latitude
/// `metersPerDegreeMeanSphere` and a degree of longitude that times the cosine of the point's
/// latitude, and measured with the clamped segment distance. A longitude is read as an angle: a
/// segment's first end is placed the short way round from the point and its second the short way
/// round from the first, so a segment stays in one piece, and where it runs past the meridian half
/// a turn from the point its far stretch is measured from the point a turn the other way.
///
/// A vertex that names no place, short of a longitude or a latitude or with either not finite,
/// ends no segment: the segment runs from the vertex before it that names a place to the next one
/// that does. Two lines are never joined. With no segment to measure to, and for a point that
/// names no place, the answer is `Double.infinity`, which every corridor width refuses.
public func metersToRoute(_ point: [Double], lines: [GeoJSONLineString]) -> Double {
  guard namesPlace(point) else { return .infinity }
  let metersPerDegreeLongitude = metersPerDegreeLongitudeAt(point[1])
  var nearest = Double.infinity
  for line in lines {
    var previous: [Double]?
    for vertex in line.coordinates where namesPlace(vertex) {
      if let from = previous {
        let distance = footAround(
          point, metersPerDegreeLongitude: metersPerDegreeLongitude, from: from, to: vertex
        ).distance
        if distance < nearest { nearest = distance }
      }
      previous = vertex
    }
  }
  return nearest
}
