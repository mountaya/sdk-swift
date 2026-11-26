// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A customer-defined fact about a waypoint, carried as a labelled key-value
  /// pair.
  ///
  /// The shape is fixed even though the vocabulary is not: `key` identifies the
  /// field across waypoints so it can be read programmatically, `label` is what a
  /// reader sees, and `format` tells a renderer how to present `value` without
  /// inspecting it. This is deliberately not an open JSON object: a closed shape
  /// stays typed in every generated client and queryable through the Data API.
  public struct WaypointProperty: Sendable, Hashable, Codable {
    /// How `value` should be rendered. Null is equivalent to `text`, and is what
    /// a client sends when it has no opinion.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var format: RestSchema.WaypointPropertyFormat??
    /// Stable machine-readable identifier for this field, as a lowercase slug.
    /// Unique within a waypoint. Reuse the same key across waypoints so readers
    /// can line the field up into a column.
    public var key: String
    /// Human-readable name of this field, shown to readers. Trimmed of leading
    /// and trailing whitespace, and refused with a 400 when nothing is left.
    public var label: String
    /// The field's value, always carried as a string.
    ///
    /// `format` says how to interpret it, and IS ENFORCED: a value declared
    /// `number` must parse as a finite number written in base ten, one declared
    /// `distance` or `duration` as such a number of zero or more, since no
    /// length or span is negative, one declared `date` must be an RFC 3339
    /// instant, and one declared `url` must be an absolute `http` or `https`
    /// address. A renderer links that last one,
    /// so the same scheme rule the contact URLs keep applies here. `text` accepts
    /// anything within the length ceiling. An empty value passes whatever the
    /// format.
    ///
    /// A `date` carries a TIME as well as a day, like every other instant on this
    /// API, and is written as a full `date-time`. A bare `YYYY-MM-DD` is accepted
    /// on write too, because it is a well-formed RFC 3339 date; a renderer reads
    /// one as midnight.
    ///
    /// The two measured formats carry the same BASE UNITS every other measure on
    /// this API does, so a reader formats them into the units their audience
    /// prefers rather than guessing: `distance` is METERS and `duration` is
    /// SECONDS. A field declared `distance` with the value `12000` is twelve
    /// kilometers.
    ///
    /// A value that does not match the format it declares is refused rather than
    /// coerced: a renderer told the field is a distance and handed `soon` has no
    /// honest way to draw it, and silently printing the text makes the format a
    /// suggestion.
    public var value: String

    /// Creates a `WaypointProperty` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      key: String,
      label: String,
      value: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.format = nil
      self.key = key
      self.label = label
      self.value = value
      configure(&self)
    }

    /// Reads a `WaypointProperty` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.format = try container.decodeMerge(
        RestSchema.WaypointPropertyFormat.self, forKey: "format")
      self.key = try container.decode(String.self, forKey: "key")
      self.label = try container.decode(String.self, forKey: "label")
      self.value = try container.decode(String.self, forKey: "value")
    }

    /// Writes a `WaypointProperty` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeMerge(self.format, forKey: "format")
      try container.encode(self.key, forKey: "key")
      try container.encode(self.label, forKey: "label")
      try container.encode(self.value, forKey: "value")
    }
  }
}
