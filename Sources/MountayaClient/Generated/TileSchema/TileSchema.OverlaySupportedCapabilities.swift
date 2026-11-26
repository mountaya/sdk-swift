// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// The optional overlay behaviours one side of the wire supports. `timestamp`
  /// means that side resolves the moment the overlay depicts: server-side by
  /// serving the tile for a requested instant, client-side by restyling data it
  /// already holds. False on both sides means the overlay has no time dimension.
  public struct OverlaySupportedCapabilities: Sendable, Hashable, Codable {
    /// Whether this side of the wire resolves the moment the overlay depicts.
    public var timestamp: Bool

    /// Creates a `OverlaySupportedCapabilities` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      timestamp: Bool,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.timestamp = timestamp
      configure(&self)
    }

    /// Reads a `OverlaySupportedCapabilities` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.timestamp = try container.decode(Bool.self, forKey: "timestamp")
    }

    /// Writes a `OverlaySupportedCapabilities` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.timestamp, forKey: "timestamp")
    }
  }
}
