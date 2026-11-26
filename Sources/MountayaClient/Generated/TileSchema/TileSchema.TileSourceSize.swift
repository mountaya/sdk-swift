// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// Edge length in pixels of one raster tile. Pass it to the `tileSize` option of
  /// `map.addSource()`. Omitted for vector sources, which have no pixel size of
  /// their own.
  ///
  /// These two values are the only ones a source can carry, and the raster
  /// overlay sources all carry 512, so a client may switch on them exhaustively
  /// rather than treating this as an open integer. Declaring a size
  /// the source does not serve offsets every zoom level rather than failing, which
  /// is why the set is closed: read it off the source instead of assuming one.
  ///
  /// The terrain sources publish 512 alone, which `TerrainTileSize` declares on its
  /// own for the variant that carries nothing else.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct TileSourceSize: RawRepresentable, Sendable, Hashable, Codable,
    ExpressibleByIntegerLiteral
  {
    /// A 256 by 256 pixel tile, the classic web-map size.
    public static let size256: Self = 256
    /// A 512 by 512 pixel tile, covering the same ground as four 256px tiles at one zoom deeper.
    public static let size512: Self = 512

    /// rawValue is the value as the wire spells it.
    public let rawValue: Int

    /// Creates a value from its wire spelling, which may be one this build has never seen.
    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    /// Creates a value from an integer literal, which is its wire spelling.
    public init(integerLiteral value: Int) {
      self.rawValue = value
    }

    /// Reads the value from its wire spelling.
    public init(from decoder: any Decoder) throws {
      self.rawValue = try decoder.singleValueContainer().decode(Int.self)
    }

    /// Writes the value as the wire spells it.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }
  }
}
