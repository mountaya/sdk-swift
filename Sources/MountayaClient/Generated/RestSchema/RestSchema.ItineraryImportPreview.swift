// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Non-persisted result of an itinerary import preview: the proposed itinerary
  /// draft a user reviews before confirming. Carries the proposed segments (each
  /// with its candidate modes and recommendation), the parsed waypoints, the
  /// best-effort name and activity, and any non-fatal warnings. No itinerary, segment, or waypoint
  /// is written.
  public struct ItineraryImportPreview: Sendable, Hashable, Codable {
    /// Best-effort itinerary name parsed from the source.
    ///
    /// Unbounded here, unlike every other name in this contract, and for the
    /// reason ItineraryImportPreview.description gives: the value is copied out
    /// of an uploaded file and is not validated until the draft is confirmed.
    /// POST /v1/itineraries/import applies the ceiling, so editing this into
    /// range is part of reviewing the draft rather than something the preview
    /// already did.
    public var name: String
    /// Best-effort itinerary description parsed from the source. Absent when the
    /// source carries none.
    ///
    /// Unbounded here, unlike every other description in this contract. The value
    /// is copied out of an uploaded file and is not validated until the draft is
    /// confirmed, so a source carrying more than 100 characters produces a preview
    /// carrying them too. POST /v1/itineraries/import applies the 100-character
    /// ceiling, which is why editing this down is part of reviewing the draft
    /// rather than something the preview already did.
    public var description: String?
    /// Activity resolved for the import: the request's `activity_id`, which an
    /// upload always carries.
    public var activity_id: String
    /// The proposed segments, in the order they would be chained. Nothing is
    /// persisted until `postItineraryImport` confirms them.
    public var segments: [RestSchema.ProposedSegment]
    /// The proposed waypoints that belong to the itinerary rather than to any one
    /// segment, in the order the source gives them.
    ///
    /// At most 5,000, the most `postItineraryImport` persists in one request, so
    /// the draft confirms as it stands: a source carrying more proposes its first
    /// 5,000 and reports `waypoints-truncated` in `warnings`.
    public var waypoints: [RestSchema.ProposedWaypoint]
    /// File-level observations reported without refusing the file, one entry
    /// per occurrence. Empty when there is nothing to report.
    public var warnings: [RestSchema.ImportWarning]

    /// Creates a `ItineraryImportPreview` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      name: String,
      activity_id: String,
      segments: [RestSchema.ProposedSegment],
      waypoints: [RestSchema.ProposedWaypoint],
      warnings: [RestSchema.ImportWarning],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = name
      self.description = nil
      self.activity_id = activity_id
      self.segments = segments
      self.waypoints = waypoints
      self.warnings = warnings
      configure(&self)
    }

    /// Reads a `ItineraryImportPreview` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decode(String.self, forKey: "name")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.activity_id = try container.decode(String.self, forKey: "activity_id")
      self.segments = try container.decode([RestSchema.ProposedSegment].self, forKey: "segments")
      self.waypoints = try container.decode([RestSchema.ProposedWaypoint].self, forKey: "waypoints")
      self.warnings = try container.decode([RestSchema.ImportWarning].self, forKey: "warnings")
    }

    /// Writes a `ItineraryImportPreview` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.name, forKey: "name")
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encode(self.activity_id, forKey: "activity_id")
      try container.encode(self.segments, forKey: "segments")
      try container.encode(self.waypoints, forKey: "waypoints")
      try container.encode(self.warnings, forKey: "warnings")
    }
  }
}
