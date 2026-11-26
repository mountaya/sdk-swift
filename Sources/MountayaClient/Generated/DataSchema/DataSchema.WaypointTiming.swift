// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Timing published for a waypoint: the instant a participant must have left it
  /// by, and how long they are expected to spend there. A cut-off is an absolute
  /// instant and nothing else.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct WaypointTiming: Sendable, Hashable, Codable {
    /// Absolute instant by which this waypoint must be left, as an RFC 3339 timestamp;
    /// null when none is published.
    public var cutoffAt: Date?
    /// Seconds expected to be spent here; null when no stop is planned.
    public var stopDuration: Int?

    /// Creates a `WaypointTiming` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.cutoffAt = nil
      self.stopDuration = nil
      configure(&self)
    }

    /// Reads a `WaypointTiming` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.cutoffAt = try container.decodeWiredIfPresent(Date.self, forKey: "cutoffAt")
      self.stopDuration = try container.decodeIfPresent(Int.self, forKey: "stopDuration")
    }

    /// Writes a `WaypointTiming` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeWiredIfPresent(self.cutoffAt, forKey: "cutoffAt")
      try container.encodeIfPresent(self.stopDuration, forKey: "stopDuration")
    }
  }
}
