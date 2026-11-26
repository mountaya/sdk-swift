// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A customer-defined fact about a waypoint, carried as a labelled key-value pair.
  ///
  /// The shape is fixed even though the vocabulary is not: key identifies the field
  /// across waypoints so it can be read programmatically, label is what a reader sees,
  /// and format says how to present value without inspecting it.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct WaypointProperty: Sendable, Hashable, Codable {
    /// Stable lowercase-slug identifier, unique within the waypoint.
    public var key: String?
    /// Human-readable name of this field, shown to readers.
    public var label: String?
    /// The field's value, always carried as a string. `format` says how to interpret it.
    public var value: String?
    /// How `value` should be rendered; null is equivalent to TEXT.
    public var format: DataSchema.WaypointPropertyFormat?

    /// Creates a `WaypointProperty` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.key = nil
      self.label = nil
      self.value = nil
      self.format = nil
      configure(&self)
    }

    /// Reads a `WaypointProperty` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.key = try container.decodeIfPresent(String.self, forKey: "key")
      self.label = try container.decodeIfPresent(String.self, forKey: "label")
      self.value = try container.decodeIfPresent(String.self, forKey: "value")
      self.format = try container.decodeIfPresent(
        DataSchema.WaypointPropertyFormat.self, forKey: "format")
    }

    /// Writes a `WaypointProperty` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.key, forKey: "key")
      try container.encodeIfPresent(self.label, forKey: "label")
      try container.encodeIfPresent(self.value, forKey: "value")
      try container.encodeIfPresent(self.format, forKey: "format")
    }
  }
}
