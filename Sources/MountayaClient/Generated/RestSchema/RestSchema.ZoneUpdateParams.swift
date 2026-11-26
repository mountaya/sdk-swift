// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for updating an existing zone. Only provided fields are updated.
  public struct ZoneUpdateParams: Sendable, Hashable, Codable {
    /// Free-text description of the zone, at most 100 characters as sent, stored
    /// with leading and trailing whitespace trimmed. Omit to keep the current
    /// value; `null`, or a value that trims to nothing, clears it.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var description: String??
    /// End of the temporal validity window. Omit to keep the current value;
    /// `null` removes the expiration. The window a request leaves must not end
    /// before it starts: an `end_at` earlier than the resulting `start_at`, sent
    /// or kept, is a `400` naming `end_at`.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var end_at: Date??
    /// Replacement area, which replaces the stored one wholesale rather than
    /// merging into it. Optional and not nullable: omit it to keep the current
    /// area. Sent on a sourced zone, it replaces the computed area and
    /// detaches the source. Mutually exclusive with `source` in the same request.
    ///
    /// The ring rules stated on `GeoJSONPolygon` are enforced here. A ring whose
    /// ends differ, a ring of fewer than four positions, a polygon carrying no
    /// ring, and a position outside the angle ranges the feature's `geometry`
    /// states are each a `400` naming the ring or position at fault, and so is
    /// an area of more than 10,000 positions in total, naming `geojson`. An
    /// outline one meridian or one parallel crosses more than 512 times, every
    /// ring counted, is too intricate to be stored, and one that is not a valid
    /// polygon, in degrees as sent or once projected to Web Mercator, as a map
    /// draws it (a ring that crosses itself or another ring, a ring that
    /// touches itself, or a hole outside its shell), is refused too: each is a
    /// `400` naming `geojson.geometry`, without saying where.
    public var geojson: RestSchema.ZoneFeature?
    /// Whether the zone is private. A private zone is reached only with the key
    /// of the organization that owns it, so a private personal zone, owned by no
    /// organization, is reached by no key. A public zone is readable by id,
    /// read-only, by any publishable key, as last published, and it is listed
    /// only in its own organization's listings. A collection's share token
    /// reaches the zones that collection holds whatever this says. Public never
    /// grants editing, which takes a write role in the owning organization.
    /// Privacy is read from the draft, so a change takes effect at once rather
    /// than at the next publish.
    /// Omit to keep the current value.
    public var is_private: Bool?
    /// How serious the zone is, which is what a renderer picks its styling from.
    /// It carries no access meaning: a zone is visible or not by `is_private`
    /// and its publication, never by its level. Optional and not nullable: omit it to keep the
    /// current
    /// level.
    public var level: RestSchema.ZoneLevel?
    /// How the area sent beside it was drawn or computed, which a client reopens
    /// the zone in. Optional and not nullable: omit it to keep the current mode.
    /// It describes an area, so it is sent with one: beside `geojson` any mode
    /// is taken, beside a `source` only `polygon` is, and a `mode` sent with
    /// neither, or another mode beside a `source`, is a `400` naming `mode`. A
    /// zone reshaped into a shape of another kind is sent the new kind's mode
    /// with its `geojson`.
    public var mode: RestSchema.ZoneMode?
    /// Display name of the zone, at most 30 characters as sent, and at least 2
    /// once leading and trailing whitespace is trimmed. Optional and not
    /// nullable: omit it to keep the current name. Refused with a `409` when
    /// another zone in the organization already carries it; names are compared
    /// exactly after trimming, case included, so `Alps` and `alps` are two
    /// different names. Sending its current name again is not a conflict. A name
    /// is one line: a tab, a line break or a line separator between two of its
    /// characters is a `400`, and one at either end is trimmed with the
    /// whitespace there.
    public var name: String?
    /// Provenance inputs for a computed zone. When provided, the zone's polygon
    /// is recomputed from these inputs and replaces the geometry, which is how a
    /// computed zone is refreshed. Only a zone whose `mode`, sent or kept, is
    /// `polygon` takes one: on any other mode it is a `400` naming `source`. Omit it to keep the
    /// current source; `null` detaches it and keeps the current area as it
    /// stands. Mutually exclusive with `geojson` in the same request.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var source: RestSchema.ZoneSource??
    /// Start of the temporal validity window. Omit to keep the current value;
    /// `null` makes the zone active immediately.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var start_at: Date??

    /// Creates a `ZoneUpdateParams` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.description = nil
      self.end_at = nil
      self.geojson = nil
      self.is_private = nil
      self.level = nil
      self.mode = nil
      self.name = nil
      self.source = nil
      self.start_at = nil
      configure(&self)
    }

    /// Reads a `ZoneUpdateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.description = try container.decodeMerge(String.self, forKey: "description")
      self.end_at = try container.decodeWiredMerge(Date.self, forKey: "end_at")
      self.geojson = try container.decodeIfPresent(RestSchema.ZoneFeature.self, forKey: "geojson")
      self.is_private = try container.decodeIfPresent(Bool.self, forKey: "is_private")
      self.level = try container.decodeIfPresent(RestSchema.ZoneLevel.self, forKey: "level")
      self.mode = try container.decodeIfPresent(RestSchema.ZoneMode.self, forKey: "mode")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.source = try container.decodeMerge(RestSchema.ZoneSource.self, forKey: "source")
      self.start_at = try container.decodeWiredMerge(Date.self, forKey: "start_at")
    }

    /// Writes a `ZoneUpdateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeMerge(self.description, forKey: "description")
      try container.encodeWiredMerge(self.end_at, forKey: "end_at")
      try container.encodeIfPresent(self.geojson, forKey: "geojson")
      try container.encodeIfPresent(self.is_private, forKey: "is_private")
      try container.encodeIfPresent(self.level, forKey: "level")
      try container.encodeIfPresent(self.mode, forKey: "mode")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeMerge(self.source, forKey: "source")
      try container.encodeWiredMerge(self.start_at, forKey: "start_at")
    }
  }
}
