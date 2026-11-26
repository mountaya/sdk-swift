// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Edge length in pixels of one elevation raster tile. Only 512 is served, and a
  /// client that assumed 256 would request four times as many tiles for the same
  /// ground and read every height off by a zoom level.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct ElevationTileSize: RawRepresentable, Sendable, Hashable, Codable,
    ExpressibleByIntegerLiteral
  {
    /// A 512 by 512 pixel tile, the only size the elevation source publishes.
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
