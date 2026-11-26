import MountayaClient

/// roadAccessFeatures cuts a segment's restricted stretches out of its `geometry`
/// (`geo.data.road-access-stretches`): one LineString feature per piece, whose property `kind` is
/// its stretch's `RoadAccessKind` as the contract spells it, `local-access`, the property the
/// itinerary tiles' restricted stretches carry, so a line drawn live and a saved one are striped by
/// the same layers.
///
/// `info` is the segment's `road_access_info`, as REST answers it, and nil or no stretch cuts
/// nothing. The lines `geometry` holds, a LineString, each line of a MultiLineString and the lines
/// a GeometryCollection holds, in order, are laid end to end, a geometry that is no line counting
/// for nothing, and a stretch's two indexes count their positions, both included. A stretch is cut
/// into one piece per line it touches and never across the gap between two lines, each piece
/// clamped to its line, so an index before the first position or past the last reads the
/// geometry's end. A piece of fewer than two positions, which covers no length, is left out, and so
/// is a stretch whose values name no kind (`roadAccessKindOf(_:)`), a value the table does not name
/// reading as `restricted`.
///
/// The pieces are in the order `info` lists the stretches, a stretch's in the order of its lines,
/// each position as the geometry writes it.
public func roadAccessFeatures(
  _ geometry: GeoJSONGeometry?, info: [RestSchema.RoadAccessInfo]?
) -> [GeoJSONFeature] {
  guard let info, !info.isEmpty else { return [] }
  let lines = linesOf(geometry)
  var features: [GeoJSONFeature] = []
  for stretch in info {
    guard let kind = roadAccessKindOf(stretch.values) else { continue }
    // The index of each line's first position, the lines laid end to end.
    var offset = 0
    for line in lines {
      let last = offset + line.count - 1
      let from = max(stretch.from_index, offset)
      let to = min(stretch.to_index, last)
      if to > from {
        features.append(
          GeoJSONFeature(
            geometry: .lineString(
              GeoJSONLineString(coordinates: Array(line[(from - offset)...(to - offset)]))),
            properties: ["kind": .string(kind.id)]))
      }
      offset = last + 1
    }
  }
  return features
}
