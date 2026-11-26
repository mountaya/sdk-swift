// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// A labelled external link attached to a waypoint.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct WaypointLink: Sendable, Hashable, Codable {
    /// Text shown for the link.
    public var label: String?
    /// Absolute URL the link points to.
    public var url: URI?

    /// Creates a `WaypointLink` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.label = nil
      self.url = nil
      configure(&self)
    }

    /// Reads a `WaypointLink` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.label = try container.decodeIfPresent(String.self, forKey: "label")
      self.url = try container.decodeIfPresent(URI.self, forKey: "url")
    }

    /// Writes a `WaypointLink` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.label, forKey: "label")
      try container.encodeIfPresent(self.url, forKey: "url")
    }
  }
}
