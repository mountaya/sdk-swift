/// terrainFromElevationTiles answers the terrain at `position`, `[longitude, latitude]`, read off
/// `tiles` of `source` (`geo.terrain.elevation-sample`).
///
/// The height is read at five places, the point and one ten-thousandth of a degree to its north,
/// south, east and west, each placed on the tile grid at the source's deepest zoom by Web Mercator
/// (`elevationTilesAt(_:source:)`), and each the bilinear mix of the four pixel centres around it,
/// decoded by the source's encoding (`decodeElevation(_:encoding:)`): each row mixed as a + (b - a) ×
/// f from its western pixel to its eastern, then the northern row and the southern the same way, so
/// pixels that agree give their own height exactly. The slope and the aspect are those
/// `slopeAspectFromNeighbours(_:latitude:spacingDegrees:)` reads over the four neighbours, at the
/// point's latitude and that spacing.
///
/// nil where a tile it needs is not among `tiles` or holds fewer bytes than its edge asks, where a
/// place reads nothing, past the world's top or bottom edge, and where the encoding decodes no
/// height.
public func terrainFromElevationTiles(
  _ position: [Double], source: ElevationSource, tiles: [ElevationTile]
) -> TerrainReading? {
  let size = source.tileSize
  var held: [[Int]: [UInt8]] = [:]
  for tile in tiles where tile.z == source.zoom && tile.pixels.count >= size * size * 3 {
    held[[tile.x, tile.y]] = tile.pixels
  }
  func height(column: Int, row: Int) -> Double? {
    guard let pixels = held[[column / size, row / size]] else { return nil }
    let at = ((row % size) * size + column % size) * 3
    return decodedHeight(
      red: pixels[at], green: pixels[at + 1], blue: pixels[at + 2], encoding: source.encoding)
  }
  var heights: [Double] = []
  for place in elevationPlaces(position, source: source) {
    guard let place,
      let northWest = height(column: place.columns.west, row: place.rows.north),
      let northEast = height(column: place.columns.east, row: place.rows.north),
      let southWest = height(column: place.columns.west, row: place.rows.south),
      let southEast = height(column: place.columns.east, row: place.rows.south)
    else { return nil }
    let north = northWest + (northEast - northWest) * place.across
    let south = southWest + (southEast - southWest) * place.across
    heights.append(north + (south - north) * place.down)
  }
  let gradient = slopeAspectFromNeighbours(
    TerrainNeighbours(north: heights[1], south: heights[2], east: heights[3], west: heights[4]),
    latitude: position[1], spacingDegrees: terrainNeighbourDegrees)
  return TerrainReading(elevation: heights[0], slope: gradient.slope, aspect: gradient.aspect)
}
