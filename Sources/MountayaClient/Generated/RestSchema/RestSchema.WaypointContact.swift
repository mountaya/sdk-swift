// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// How to reach the place a waypoint marks: a hut to book, a shop to call, an aid
  /// station to find. Deliberately a flat, single-line shape rather than a
  /// structured postal address: an itinerary waypoint is a place on a map, not a
  /// billing party. Null when the waypoint carries no contact details.
  public struct WaypointContact: Sendable, Hashable, Codable {
    /// Postal address on a single line, as it would be written on an envelope or
    /// typed into a navigation app. Null when not provided.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var address: String??
    /// Absolute `http` or `https` URL where a stay, table or slot at this place
    /// can be booked. Any other scheme is rejected: a renderer turns this into a
    /// link a reader clicks, so `javascript:` and `data:` are refused at the API
    /// rather than left for each client to remember. Null when not provided.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var booking_url: URI??
    /// Contact email address for this place, parsed as an RFC 5322 address; a
    /// value that does not parse as one is a 400. Null when not provided.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var email: String??
    /// Opening hours in free text, as published by the place itself: seasons,
    /// days and hours vary too much between huts, shops and aid stations to be
    /// worth structuring. Null when not provided.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var opening_hours: String??
    /// Contact phone number, in international format where known. Digits, spaces
    /// and the punctuation a printed number uses (`+ - . ( ) /`), starting with a
    /// digit, a `+` or a `(` and carrying at least three digits. Free text is
    /// refused: a renderer turns this into a `tel:` link, and a number that
    /// cannot be dialled is worse than no number at all. Null when not provided.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var phone: String??
    /// Absolute `http` or `https` URL of this place's website. Any other scheme
    /// is rejected, for the reason `booking_url` states. Null when not provided.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var website: URI??

    /// Creates a `WaypointContact` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.address = nil
      self.booking_url = nil
      self.email = nil
      self.opening_hours = nil
      self.phone = nil
      self.website = nil
      configure(&self)
    }

    /// Reads a `WaypointContact` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.address = try container.decodeMerge(String.self, forKey: "address")
      self.booking_url = try container.decodeWiredMerge(URI.self, forKey: "booking_url")
      self.email = try container.decodeMerge(String.self, forKey: "email")
      self.opening_hours = try container.decodeMerge(String.self, forKey: "opening_hours")
      self.phone = try container.decodeMerge(String.self, forKey: "phone")
      self.website = try container.decodeWiredMerge(URI.self, forKey: "website")
    }

    /// Writes a `WaypointContact` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeMerge(self.address, forKey: "address")
      try container.encodeWiredMerge(self.booking_url, forKey: "booking_url")
      try container.encodeMerge(self.email, forKey: "email")
      try container.encodeMerge(self.opening_hours, forKey: "opening_hours")
      try container.encodeMerge(self.phone, forKey: "phone")
      try container.encodeWiredMerge(self.website, forKey: "website")
    }
  }
}
