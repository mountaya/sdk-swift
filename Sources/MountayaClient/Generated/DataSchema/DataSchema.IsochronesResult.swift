// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Result of an isochrones computation.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct IsochronesResult: Sendable, Hashable, Codable {
    /// List of computed isochrones: one per location and range value, in the order
    /// the routing engine returns them. Read each one's `value` rather than relying
    /// on its position.
    public var isochrones: [DataSchema.Isochrone]?

    /// Creates a `IsochronesResult` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.isochrones = nil
      configure(&self)
    }

    /// Reads a `IsochronesResult` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.isochrones = try container.decodeIfPresent(
        [DataSchema.Isochrone].self, forKey: "isochrones")
    }

    /// Writes a `IsochronesResult` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.isochrones, forKey: "isochrones")
    }
  }
}
