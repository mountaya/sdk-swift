// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Photos and external links attached to a waypoint. Media is referenced by URL
  /// rather than uploaded: Mountaya stores the address, never the bytes. Null when
  /// the waypoint carries no media.
  public struct WaypointMedia: Sendable, Hashable, Codable {
    /// Labelled external links, in the order they should be shown. Null when none
    /// are attached. Never an empty array. At most 10: the server enforces the
    /// ceiling, and a list over it is a validation error rather than a
    /// truncation.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var links: [RestSchema.WaypointLink]??
    /// Photographs of the place, in the order they should be shown. Null when
    /// none are attached. Never an empty array. At most 10: the server enforces
    /// the ceiling, and a list over it is a validation error rather than a
    /// truncation.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var photos: [RestSchema.WaypointPhoto]??

    /// Creates a `WaypointMedia` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.links = nil
      self.photos = nil
      configure(&self)
    }

    /// Reads a `WaypointMedia` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.links = try container.decodeMerge([RestSchema.WaypointLink].self, forKey: "links")
      self.photos = try container.decodeMerge([RestSchema.WaypointPhoto].self, forKey: "photos")
    }

    /// Writes a `WaypointMedia` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeMerge(self.links, forKey: "links")
      try container.encodeMerge(self.photos, forKey: "photos")
    }
  }
}
