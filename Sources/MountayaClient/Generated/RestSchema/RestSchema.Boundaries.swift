// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Geographic bounding box with a display name, used to define a named region on
  /// the map.
  public struct Boundaries: Sendable, Hashable, Codable {
    /// Bounding box as [minLongitude, minLatitude, maxLongitude, maxLatitude] in
    /// WGS 84 decimal degrees. This is the flat four-tuple every bounding box on
    /// every Mountaya surface uses, so a client reads one shape everywhere.
    /// Exactly four numbers, longitude first in each pair; the minimum corner
    /// comes first.
    ///
    /// The bound is WGS 84's own: a coordinate outside it names no point on
    /// Earth, and this box is evaluated on every tile request that carries one,
    /// so a nonsensical value is not merely inert. `items` holds the widest of
    /// the two ranges because a tuple's positions cannot be typed apart in JSON
    /// Schema; the per-position latitude range is enforced where the box is
    /// written.
    public var bbox: [Double]
    /// Display name of the bounded region. Bounded in length because it is stored
    /// per organization and echoed back on every settings read.
    public var name: String

    /// Creates a `Boundaries` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      bbox: [Double],
      name: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.bbox = bbox
      self.name = name
      configure(&self)
    }

    /// Reads a `Boundaries` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.bbox = try container.decode([Double].self, forKey: "bbox")
      self.name = try container.decode(String.self, forKey: "name")
    }

    /// Writes a `Boundaries` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.bbox, forKey: "bbox")
      try container.encode(self.name, forKey: "name")
    }
  }
}
