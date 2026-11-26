import Foundation

/// terrainNeighbourDegrees is how far from a point its four neighbours are read off the elevation
/// tiles (`geo.terrain.elevation-sample`), in degrees of latitude and of longitude: one
/// ten-thousandth, about 11 meters north and south.
public let terrainNeighbourDegrees = 0.0001

/// ElevationPlace is where one of the places the terrain is read at falls on an elevation source's
/// pixel grid: the two columns and the two rows of the pixel centres around it, each column taken
/// by whole turns of the world, and how far it stands past the western column and the northern
/// row, each from 0 to 1.
struct ElevationPlace: Sendable {
  let columns: (west: Int, east: Int)
  let rows: (north: Int, south: Int)
  let across: Double
  let down: Double
}

/// elevationPlaces places the point `position`, `[longitude, latitude]`, and its neighbours to the
/// north, south, east and west, in that order, on `source`'s pixel grid at its deepest zoom, by Web
/// Mercator: a world pixel's `x` is (longitude + 180) / 360 × 2^zoom × tileSize and its `y` is
/// (1 - ln(tan(π/4 + latitude / 2)) / π) / 2 × 2^zoom × tileSize, and a pixel's centre stands half
/// a pixel past its corner. A place whose pixels pass the world's top or bottom edge, as a point
/// past Web Mercator's latitude does, is nil, and so is every place of a point that is no two
/// finite numbers or of a source no grid holds: a tile edge from 1 to 65,536 pixels and a zoom
/// from 0 to 30.
func elevationPlaces(_ position: [Double], source: ElevationSource) -> [ElevationPlace?] {
  guard position.count >= 2, position[0].isFinite, position[1].isFinite,
    (1...65_536).contains(source.tileSize), (0...30).contains(source.zoom)
  else { return [nil, nil, nil, nil, nil] }
  let longitude = position[0]
  let latitude = position[1]
  let d = terrainNeighbourDegrees
  let points = [
    (longitude, latitude), (longitude, latitude + d), (longitude, latitude - d),
    (longitude + d, latitude), (longitude - d, latitude),
  ]
  let scale = Double(1 << source.zoom)
  let edge = Double(source.tileSize)
  let world = (1 << source.zoom) * source.tileSize
  return points.map { point -> ElevationPlace? in
    let radians = point.1 * .pi / 180
    let x = (point.0 + 180) / 360 * scale * edge
    let y = (1 - log(tan(.pi / 4 + radians / 2)) / .pi) / 2 * scale * edge
    let u = x - 0.5
    let v = y - 0.5
    guard u.isFinite, v.isFinite, abs(u) < 1e15, abs(v) < 1e15 else { return nil }
    let column = Int(u.rounded(.down))
    let row = Int(v.rounded(.down))
    guard row >= 0, row + 1 < world else { return nil }
    func wrapped(_ column: Int) -> Int {
      let folded = column % world
      return folded < 0 ? folded + world : folded
    }
    return ElevationPlace(
      columns: (wrapped(column), wrapped(column + 1)), rows: (row, row + 1),
      across: u - u.rounded(.down), down: v - v.rounded(.down))
  }
}

/// elevationTilesAt answers the tiles of `source` the terrain at `position`, `[longitude,
/// latitude]`, is read off (`geo.terrain.elevation-sample`), each named by its address alone: the
/// tiles at the source's deepest zoom holding the four pixel centres around the point and around
/// each of its neighbours one ten-thousandth of a degree to its north, south, east and west,
/// ordered by `x` then `y`, each once. A tile across the antimeridian is the one its column reaches
/// by whole turns, and a pixel past the world's top or bottom edge needs none.
public func elevationTilesAt(_ position: [Double], source: ElevationSource) -> [ElevationTile] {
  var addresses: Set<[Int]> = []
  for place in elevationPlaces(position, source: source) {
    guard let place else { continue }
    for column in [place.columns.west, place.columns.east] {
      for row in [place.rows.north, place.rows.south] {
        addresses.insert([column / source.tileSize, row / source.tileSize])
      }
    }
  }
  return addresses.sorted { $0[0] != $1[0] ? $0[0] < $1[0] : $0[1] < $1[1] }.map {
    ElevationTile(z: source.zoom, x: $0[0], y: $0[1])
  }
}
