// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A geographic cursor position, in decimal degrees (WGS84). Null when the
  /// collaborator's cursor has left the canvas.
  public struct CollabPosition: Sendable, Hashable, Codable {
    /// Longitude in decimal degrees, east of the prime meridian for a positive
    /// value. Bounded because a value outside the range names no point on Earth,
    /// and this one is broadcast to every other collaborator in the session
    /// rather than stored, so nothing downstream will reject it later.
    public var lng: Double
    /// Latitude in decimal degrees, north of the equator for a positive value.
    /// Bounded for the reason `lng` is, and to the narrower range: a cursor
    /// cannot be past a pole.
    public var lat: Double

    /// Creates a `CollabPosition` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      lng: Double,
      lat: Double,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.lng = lng
      self.lat = lat
      configure(&self)
    }

    /// Reads a `CollabPosition` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.lng = try container.decode(Double.self, forKey: "lng")
      self.lat = try container.decode(Double.self, forKey: "lat")
    }

    /// Writes a `CollabPosition` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.lng, forKey: "lng")
      try container.encode(self.lat, forKey: "lat")
    }
  }
}
