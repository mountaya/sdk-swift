import MountayaClient

/// matrixLineMinWidth is the width the cheapest connector of a matrix draws at, in pixels.
public let matrixLineMinWidth = 1.0

/// matrixLineMaxWidth is the width the dearest connector of a matrix draws at, in pixels.
public let matrixLineMaxWidth = 6.0

/// matrixLineWidth is the width a connector costing `value` draws at in a matrix whose cheapest
/// connector costs `min` and dearest `max`: from `matrixLineMinWidth` to `matrixLineMaxWidth`,
/// `1 + (value - min) / (max - min) * 5`, held within the two. A grid with no spread, and a value
/// or a bound that is no finite number, draws at the least, never at a width that is no number.
public func matrixLineWidth(_ value: Double, min: Double, max: Double) -> Double {
  guard value.isFinite, min.isFinite, max.isFinite, max > min else { return matrixLineMinWidth }
  let width =
    matrixLineMinWidth + (value - min) / (max - min) * (matrixLineMaxWidth - matrixLineMinWidth)
  return clampNumber(width, to: matrixLineMinWidth...matrixLineMaxWidth)
}

/// matrixGeoJson draws a matrix answer, which holds no geometry: one straight `matrix-connector`
/// line per solved pair of distinct locations of `input`, of the first metric it asked for, then
/// one `matrix-location` point per location.
///
/// A row of the grid is the location `sources` lists at its place, every location where it lists
/// none, and a column the one `destinations` lists, so a subset grid draws from the right places.
/// A cell the router could not solve (`null`, or no finite number) and a location's pair with
/// itself draw nothing, nor does a metric this build does not know, which names no grid; a cell
/// whose location is out of the list still counts toward the grid's extremes and draws nothing. A
/// connector's properties are `from` and `to` (the locations' places), `metric`, `value`,
/// `mtyaKind` and `mtyaWidth`, its `matrixLineWidth(_:min:max:)` between the least and the
/// greatest cost drawn; a location's are `mtyaIndex` and `mtyaKind`, and one that names no place
/// is a feature with no geometry.
public func matrixGeoJson(
  _ input: DataSchema.MatrixInput, result: DataSchema.MatrixResult
) -> GeoJSONFeatureCollection {
  let metric = input.metrics.first ?? .duration
  let grid: [[Double?]]?
  switch metric {
  case .distance: grid = result.distances
  case .duration: grid = result.durations
  default: grid = nil
  }
  let locations = input.locations
  let sources = input.sources ?? Array(locations.indices)
  let destinations = input.destinations ?? Array(locations.indices)
  var solved: [(from: Int, to: Int, value: Double)] = []
  var least = Double.infinity
  var greatest = -Double.infinity
  for (row, from) in sources.enumerated() {
    for (column, to) in destinations.enumerated() {
      guard let grid, grid.indices.contains(row), grid[row].indices.contains(column),
        let value = grid[row][column], value.isFinite, from != to
      else { continue }
      solved.append((from, to, value))
      least = Swift.min(least, value)
      greatest = Swift.max(greatest, value)
    }
  }
  let connectors = solved.compactMap { cell -> GeoJSONFeature? in
    guard locations.indices.contains(cell.from), locations.indices.contains(cell.to) else {
      return nil
    }
    return GeoJSONFeature(
      geometry: .lineString(
        GeoJSONLineString(coordinates: [locations[cell.from], locations[cell.to]])),
      properties: featureProperties(
        ("from", numberProperty(cell.from)),
        ("metric", .string(metric.rawValue)),
        ("to", numberProperty(cell.to)),
        ("value", .number(cell.value)),
        (featureKindProperty, "matrix-connector"),
        (featureWidthProperty, .number(matrixLineWidth(cell.value, min: least, max: greatest)))))
  }
  let points = locations.enumerated().map { index, location in
    GeoJSONFeature(
      geometry: pointOrNil(location),
      properties: featureProperties(
        (featureIndexProperty, numberProperty(index)),
        (featureKindProperty, "matrix-location")))
  }
  return GeoJSONFeatureCollection(features: connectors + points)
}
