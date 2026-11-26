// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// One standalone waypoint carried through an import preview unchanged from the
  /// parsed source. The user may edit or drop it before confirming.
  public struct ProposedWaypoint: Sendable, Hashable, Codable {
    /// Waypoint mode: poi when the source carried a mappable icon, otherwise
    /// point.
    public var mode: RestSchema.WaypointMode
    /// GeoJSON Point representing the waypoint location.
    public var geojson: RestSchema.GeoJSONGeometry
    /// Proposed waypoint name, 2 to 30 characters: the name the file carried,
    /// trimmed and shortened to 30 characters. A `poi` always carries one, a
    /// default drawn from its icon when the file named nothing, since a `poi`
    /// requires a name; a `point` the file named nothing for omits it. Sent back
    /// unchanged, it is accepted by the import confirm step.
    public var name: String?
    /// Best-effort waypoint description. Omitted when the source carried none.
    ///
    /// Unbounded here, unlike every other description in this contract, and for the
    /// reason ItineraryImportPreview.description gives: the value is copied out
    /// of an uploaded file and is not validated until the draft is confirmed.
    /// POST /v1/itineraries/import applies the ceiling, so editing this into
    /// range is part of reviewing the draft rather than something the preview
    /// already did.
    public var description: String?
    /// Best-effort waypoint icon. Omitted when the source symbol could not be
    /// mapped.
    public var icon: RestSchema.WaypointIcon?

    /// Creates a `ProposedWaypoint` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      mode: RestSchema.WaypointMode,
      geojson: RestSchema.GeoJSONGeometry,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.mode = mode
      self.geojson = geojson
      self.name = nil
      self.description = nil
      self.icon = nil
      configure(&self)
    }

    /// Reads a `ProposedWaypoint` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.mode = try container.decode(RestSchema.WaypointMode.self, forKey: "mode")
      self.geojson = try container.decode(RestSchema.GeoJSONGeometry.self, forKey: "geojson")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.icon = try container.decodeIfPresent(RestSchema.WaypointIcon.self, forKey: "icon")
    }

    /// Writes a `ProposedWaypoint` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.mode, forKey: "mode")
      try container.encode(self.geojson, forKey: "geojson")
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encodeIfPresent(self.icon, forKey: "icon")
    }
  }
}
