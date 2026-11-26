/// ElevationSource is the elevation raster a map reads heights off (`geo.terrain.elevation-sample`):
/// the `encoding` and the `maxzoom` its TileJSON document names (`getElevationTileJson`) and the
/// edge of its tiles, the catalog's `elevation.tile_size`.
///
/// Two are equal where they hold the same encoding and the same numbers, and equal values hash
/// alike.
public struct ElevationSource: Sendable, Hashable {
  /// encoding is how the tiles' pixels stand for heights, `mapbox` where the document names none.
  public var encoding: ElevationEncoding
  /// tileSize is the edge of a tile, in pixels.
  public var tileSize: Int
  /// zoom is the deepest zoom the source serves, its TileJSON's `maxzoom`, which the terrain is
  /// read at.
  public var zoom: Int

  /// Creates a source from its encoding, the edge of its tiles and its deepest zoom.
  public init(encoding: ElevationEncoding = .mapbox, tileSize: Int, zoom: Int) {
    self.encoding = encoding
    self.tileSize = tileSize
    self.zoom = zoom
  }
}
