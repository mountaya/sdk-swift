// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Reference to an OpenStreetMap feature with the matched tag.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct OSMRef: Sendable, Hashable, Codable {
    /// OpenStreetMap identifier of the feature.
    public var id: String?
    /// Primitive kind of the feature: node, way, or relation.
    public var type: DataSchema.OSMType?
    /// Matched OSM tag key. Example: "place" or "highway".
    public var key: String?
    /// Matched OSM tag value. Example: "city" or "residential".
    public var value: String?

    /// Creates a `OSMRef` from the properties the contract requires, the optional ones being set in
    /// `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = nil
      self.type = nil
      self.key = nil
      self.value = nil
      configure(&self)
    }

    /// Reads a `OSMRef` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decodeIfPresent(String.self, forKey: "id")
      self.type = try container.decodeIfPresent(DataSchema.OSMType.self, forKey: "type")
      self.key = try container.decodeIfPresent(String.self, forKey: "key")
      self.value = try container.decodeIfPresent(String.self, forKey: "value")
    }

    /// Writes a `OSMRef` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.id, forKey: "id")
      try container.encodeIfPresent(self.type, forKey: "type")
      try container.encodeIfPresent(self.key, forKey: "key")
      try container.encodeIfPresent(self.value, forKey: "value")
    }
  }
}
