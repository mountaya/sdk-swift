// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for duplicating an itinerary into the key's organization,
  /// optionally keeping only part of its content. Omitting both `segment_ids` and
  /// `waypoint_ids` copies the itinerary whole, however many segments and
  /// waypoints it holds; the lists are for a partial copy. Either way a source
  /// holding more than 500,000 positions is not copied: `postItineraryDuplicate`
  /// refuses it with a `413`.
  ///
  /// Duplication is a pure copy: the selected segments keep their stored geometry
  /// and metrics verbatim and are never re-routed, so the copy is byte-identical to
  /// what the source shows. The copy is always private, never carries the source's
  /// share link, and starts unpublished.
  public struct ItineraryDuplicateParams: Sendable, Hashable, Codable {
    /// Display name of the new itinerary, 2 to 30 characters as sent. Leading
    /// and trailing whitespace is then trimmed, and what remains must still be at
    /// least 2 characters. Refused with a `409` when another itinerary in the
    /// organization already carries it. A name is one line: a tab, a line break
    /// or a line separator between two of its characters is a `400`, and one at
    /// either end is trimmed with the whitespace there.
    public var name: String
    /// Identifier of the organization that will own the copy. It must be the
    /// key's organization; omitted, it is that organization, whichever
    /// organization the source itinerary belongs to.
    public var organization_id: String?
    /// Identifiers of the source segments to copy, for a partial copy. Optional
    /// and not nullable: omit it to copy every segment of the source's chain,
    /// however many it holds, read from the source as the `surface` parameter
    /// describes, so a whole copy of a published snapshot never names ids that
    /// change at every publish.
    ///
    /// Sent, the ids must form a contiguous run of the source's chain, which is
    /// what keeps the copy a connected route: trimming from either end is
    /// allowed, dropping an interior segment is not. At least one is required,
    /// so an empty list is a `400` naming `segment_ids`.
    ///
    /// The ids are those of the source as it is read, which the `surface`
    /// parameter describes: a published snapshot's segments carry their own ids,
    /// which change at every publish. An id that is not a segment of the source
    /// as read is a `400` naming its position in the array, not a `404`.
    ///
    /// A source group is carried over only when at least two of its members are
    /// kept.
    ///
    /// At most 1,000, the ceiling the import confirm puts on the segments of one
    /// request: a list names work bought with one request, so it is bounded,
    /// while omitting it copies the chain whole whatever its length. Over it is
    /// a validation error, never a truncation.
    ///
    /// A repeated identifier is refused rather than collapsed, because a repeat
    /// would make the run read as shorter than it is and let a selection that is
    /// not contiguous pass the span check.
    public var segment_ids: [String]?
    /// Identifiers of the source waypoints to copy, for a partial copy.
    /// Waypoints are standalone markers, so any subset is valid, and an empty
    /// list copies none. Optional and not nullable: omit it to copy every
    /// waypoint of the source as read, however many it holds. At most 5,000,
    /// the ceiling the import confirm puts on the waypoints of one request. As
    /// with `segment_ids`, an id that is not a waypoint of the source as read
    /// is a `400` naming its position in the array, and a repeated identifier
    /// is a `400` naming the repeat, as it is for `segment_ids`.
    public var waypoint_ids: [String]?

    /// Creates a `ItineraryDuplicateParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      name: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = name
      self.organization_id = nil
      self.segment_ids = nil
      self.waypoint_ids = nil
      configure(&self)
    }

    /// Reads a `ItineraryDuplicateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decode(String.self, forKey: "name")
      self.organization_id = try container.decodeIfPresent(String.self, forKey: "organization_id")
      self.segment_ids = try container.decodeIfPresent([String].self, forKey: "segment_ids")
      self.waypoint_ids = try container.decodeIfPresent([String].self, forKey: "waypoint_ids")
    }

    /// Writes a `ItineraryDuplicateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.name, forKey: "name")
      try container.encodeIfPresent(self.organization_id, forKey: "organization_id")
      try container.encodeIfPresent(self.segment_ids, forKey: "segment_ids")
      try container.encodeIfPresent(self.waypoint_ids, forKey: "waypoint_ids")
    }
  }
}
