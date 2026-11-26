/// ElevationTile is one tile of the elevation raster: its address, `z`, `x` and `y` on the tile
/// grid, and its pixels, read out of its image by the platform's own codec.
///
/// `pixels` holds the rows from the north down, each row's pixels from the west, each pixel its
/// red, green and blue, one byte each, so a tile of edge `n` holds `n × n × 3` bytes. A tile named
/// by its address alone, as `elevationTilesAt(_:source:)` names the tiles a point needs, holds
/// none.
///
/// Two are equal where they hold the same address and the same bytes, and equal values hash
/// alike.
public struct ElevationTile: Sendable, Hashable {
  /// z is the tile's zoom.
  public var z: Int
  /// x is the tile's column, from 0 at the antimeridian eastward.
  public var x: Int
  /// y is the tile's row, from 0 at the grid's northern edge southward.
  public var y: Int
  /// pixels is the tile's red, green and blue bytes, row by row from the north, or none.
  public var pixels: [UInt8]

  /// Creates a tile at `z`, `x` and `y` holding `pixels`, none where none are given.
  public init(z: Int, x: Int, y: Int, pixels: [UInt8] = []) {
    self.z = z
    self.x = x
    self.y = y
    self.pixels = pixels
  }
}
