/// rowAt is the row a profile's cursor `distance` meters from the itinerary's start stands in
/// (`geo.profile.row-match`): the one whose span holds the distance as `stretchAt(_:distance:)`
/// reads a stretch, so the later of two rows holds the meter they share, the last meter of a row
/// nothing follows stays in that row, and a row of no length holds nothing. The row the map lights
/// and the stretch a hover card names are then one answer. The row is answered as given, nil in
/// none.
public func rowAt<Row: ProfileSpan>(_ rows: [Row], distance: Double) -> Row? {
  let spans = rows.enumerated().map {
    RowSpan(from: $0.element.from, to: $0.element.to, index: $0.offset)
  }
  return stretchAt(spans, distance: distance).map { rows[$0.index] }
}

/// RowSpan is a row's span with its place in the list, so the stretch the cursor reads names the
/// row as it was given.
private struct RowSpan: ProfileSpan {
  var from: Double
  var to: Double
  let index: Int
}
