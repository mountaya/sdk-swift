// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// Where each of an overlay's optional capabilities is handled. The two sides are
  /// declared separately because they are independent: the same capability can be
  /// answered in the tile, answered by the client, answered by both, or answered by
  /// neither.
  public struct OverlayCapabilities: Sendable, Hashable, Codable {
    /// Which of the optional behaviours the CLIENT is expected to provide for
    /// this overlay, such as restyling data it already holds when the moment
    /// changes.
    public var client: TileSchema.OverlaySupportedCapabilities
    /// Which of the optional behaviours the SERVER provides for this overlay,
    /// such as serving the tile for a requested instant.
    public var server: TileSchema.OverlaySupportedCapabilities

    /// Creates a `OverlayCapabilities` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      client: TileSchema.OverlaySupportedCapabilities,
      server: TileSchema.OverlaySupportedCapabilities,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.client = client
      self.server = server
      configure(&self)
    }

    /// Reads a `OverlayCapabilities` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.client = try container.decode(
        TileSchema.OverlaySupportedCapabilities.self, forKey: "client")
      self.server = try container.decode(
        TileSchema.OverlaySupportedCapabilities.self, forKey: "server")
    }

    /// Writes a `OverlayCapabilities` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.client, forKey: "client")
      try container.encode(self.server, forKey: "server")
    }
  }
}
