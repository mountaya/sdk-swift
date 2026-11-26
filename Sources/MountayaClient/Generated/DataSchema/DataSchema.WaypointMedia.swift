// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Photos and external links attached to a waypoint. Media is referenced by URL
  /// rather than uploaded: Mountaya stores the address, never the bytes.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct WaypointMedia: Sendable, Hashable, Codable {
    /// Photographs of the place, in display order. Null when none are attached: the
    /// empty case is carried as null rather than as an empty list.
    public var photos: [DataSchema.WaypointPhoto]?
    /// Labelled external links, in display order. Null when none are attached: the
    /// empty case is carried as null rather than as an empty list.
    public var links: [DataSchema.WaypointLink]?

    /// Creates a `WaypointMedia` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.photos = nil
      self.links = nil
      configure(&self)
    }

    /// Reads a `WaypointMedia` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.photos = try container.decodeIfPresent([DataSchema.WaypointPhoto].self, forKey: "photos")
      self.links = try container.decodeIfPresent([DataSchema.WaypointLink].self, forKey: "links")
    }

    /// Writes a `WaypointMedia` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.photos, forKey: "photos")
      try container.encodeIfPresent(self.links, forKey: "links")
    }
  }
}
