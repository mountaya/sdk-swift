// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// How to reach the place a waypoint marks. Deliberately flat and single-line rather
  /// than a structured postal address: an itinerary waypoint is a place on a map, not
  /// a billing party.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct WaypointContact: Sendable, Hashable, Codable {
    /// Absolute URL of this place's website; null when not provided.
    public var website: URI?
    /// Contact phone number, in international format where known; null when not provided.
    public var phone: String?
    /// Contact email address; null when not provided.
    public var email: String?
    /// Postal address on a single line; null when not provided.
    public var address: String?
    /// Opening hours in free text, as published by the place itself; null when not provided.
    public var openingHours: String?
    /// Absolute URL where a stay, table or slot can be booked; null when not provided.
    public var bookingUrl: URI?

    /// Creates a `WaypointContact` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.website = nil
      self.phone = nil
      self.email = nil
      self.address = nil
      self.openingHours = nil
      self.bookingUrl = nil
      configure(&self)
    }

    /// Reads a `WaypointContact` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.website = try container.decodeIfPresent(URI.self, forKey: "website")
      self.phone = try container.decodeIfPresent(String.self, forKey: "phone")
      self.email = try container.decodeIfPresent(String.self, forKey: "email")
      self.address = try container.decodeIfPresent(String.self, forKey: "address")
      self.openingHours = try container.decodeIfPresent(String.self, forKey: "openingHours")
      self.bookingUrl = try container.decodeIfPresent(URI.self, forKey: "bookingUrl")
    }

    /// Writes a `WaypointContact` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.website, forKey: "website")
      try container.encodeIfPresent(self.phone, forKey: "phone")
      try container.encodeIfPresent(self.email, forKey: "email")
      try container.encodeIfPresent(self.address, forKey: "address")
      try container.encodeIfPresent(self.openingHours, forKey: "openingHours")
      try container.encodeIfPresent(self.bookingUrl, forKey: "bookingUrl")
    }
  }
}
