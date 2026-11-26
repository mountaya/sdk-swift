/// ElevationEncoding is how the pixels of an elevation tile stand for heights: the `encoding` the
/// elevation source's TileJSON document names (`getElevationTileJson`), as the style
/// specification reads a `raster-dem` source's (`geo.terrain.elevation-decode`).
///
/// The set is open: an encoding this build has never seen reads as itself, and decodes to no
/// height. Two are equal where they are spelled with the same scalars, compared whole, so
/// `Mapbox` is no `mapbox`.
public struct ElevationEncoding: RawRepresentable, Sendable, Hashable {
  /// mapbox is Mapbox's Terrain-RGB, the style specification's default: -10000 + (R × 65536 + G ×
  /// 256 + B) × 0.1 meters.
  public static let mapbox = ElevationEncoding(rawValue: "mapbox")
  /// terrarium is Terrarium's: R × 256 + G + B / 256 - 32768 meters.
  public static let terrarium = ElevationEncoding(rawValue: "terrarium")

  /// rawValue is the encoding as the TileJSON document spells it.
  public let rawValue: String

  /// Creates an encoding from its spelling, which may be one this build has never seen.
  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  /// Two encodings are equal where they are spelled with the same scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.rawValue, rhs.rawValue)
  }

  /// hash feeds the spelling's scalars.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(Array(rawValue.unicodeScalars))
  }
}
