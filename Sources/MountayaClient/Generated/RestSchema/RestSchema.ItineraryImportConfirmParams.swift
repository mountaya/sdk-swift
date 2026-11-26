// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for confirming (persisting) a reviewed itinerary import draft. The
  /// whole draft is persisted atomically: the itinerary name, privacy, and
  /// activity, the ordered finalized segments, and the finalized waypoints. Every
  /// segment's metrics are recomputed server-side from its defining geometry and
  /// are never accepted as inputs.
  public struct ItineraryImportConfirmParams: Sendable, Hashable, Codable {
    /// Display name of the new itinerary, 2 to 30 characters as sent. Leading
    /// and trailing whitespace is then trimmed, and what remains must still be at
    /// least 2 characters. Refused with a `409` when another itinerary in the
    /// organization already carries it. A name is one line: a tab, a line break
    /// or a line separator between two of its characters is a `400`, and one at
    /// either end is trimmed with the whitespace there.
    public var name: String
    /// Free-text description of the itinerary, at most 100 characters as sent,
    /// leading and trailing whitespace included; that whitespace is then
    /// trimmed. Omit it, or send one that trims to nothing, to create the
    /// itinerary without one.
    public var description: String?
    /// Whether the itinerary is private. A private itinerary is reached only with
    /// the key of the organization that owns it, so a private personal itinerary,
    /// owned by no organization, is reached by no key. A public itinerary is
    /// readable by id, read-only, by any publishable key, as last published, and
    /// it is listed only in its own organization's listings. A share token
    /// reaches only what its link names, the itinerary or a collection holding
    /// it, and reaches it whatever this says. Public never grants editing, which
    /// takes a write role in the owning organization. Privacy is read from the
    /// draft, so a change takes effect at once rather than at the next publish.
    public var is_private: Bool
    /// Identifier of the activity type for the itinerary, one `getActivities`
    /// lists; any other identifier is a `400`.
    public var activity_id: String
    /// Identifier of the organization that will own the imported itinerary. It
    /// must be the key's organization; omitted, it is that organization.
    public var organization_id: String?
    /// Ordered finalized segments to persist.
    ///
    /// At most 1,000, a bound on the size of one request rather than on what an
    /// itinerary may hold: a preview proposes at most 60 segments, and a draft
    /// edited past 1,000 is a `400` naming `segments`.
    public var segments: [RestSchema.ItineraryImportConfirmSegment]
    /// The waypoints to persist, as reviewed. Sending an empty array persists no
    /// waypoints, which is not the same as omitting the field.
    ///
    /// At most 5,000, a bound on the size of one request rather than on what an
    /// itinerary may hold: a preview proposes at most 5,000 waypoints, and a
    /// draft edited past 5,000 is a `400` naming `waypoints`.
    public var waypoints: [RestSchema.ItineraryImportConfirmWaypoint]

    /// Creates a `ItineraryImportConfirmParams` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      name: String,
      is_private: Bool,
      activity_id: String,
      segments: [RestSchema.ItineraryImportConfirmSegment],
      waypoints: [RestSchema.ItineraryImportConfirmWaypoint],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = name
      self.description = nil
      self.is_private = is_private
      self.activity_id = activity_id
      self.organization_id = nil
      self.segments = segments
      self.waypoints = waypoints
      configure(&self)
    }

    /// Reads a `ItineraryImportConfirmParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decode(String.self, forKey: "name")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.is_private = try container.decode(Bool.self, forKey: "is_private")
      self.activity_id = try container.decode(String.self, forKey: "activity_id")
      self.organization_id = try container.decodeIfPresent(String.self, forKey: "organization_id")
      self.segments = try container.decode(
        [RestSchema.ItineraryImportConfirmSegment].self, forKey: "segments")
      self.waypoints = try container.decode(
        [RestSchema.ItineraryImportConfirmWaypoint].self, forKey: "waypoints")
    }

    /// Writes a `ItineraryImportConfirmParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.name, forKey: "name")
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encode(self.is_private, forKey: "is_private")
      try container.encode(self.activity_id, forKey: "activity_id")
      try container.encodeIfPresent(self.organization_id, forKey: "organization_id")
      try container.encode(self.segments, forKey: "segments")
      try container.encode(self.waypoints, forKey: "waypoints")
    }
  }
}
