// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Provenance for a computed zone: the generative inputs its polygon is computed
  /// from, in place of client-supplied geometry. Present (and echoed back) for a
  /// computed zone; null for a zone drawn by hand. The polygon is computed on
  /// create and recomputed only by a `patchZone` that sends this object again,
  /// which is how a zone is refreshed, and there is no separate recompute
  /// endpoint. A `patchZone` sending `geojson` replaces the area and clears this
  /// object, one sending `source: null` clears it and keeps the area, and every
  /// other write keeps both.
  ///
  /// A create or `patchZone` that carries this object and passes validation runs
  /// the computation, even when it re-sends an unchanged source. Under a key each
  /// run is recorded against the key's organization as an `isochrones`
  /// computation on the `studio-embedded` data usage surface: `requests` for every run,
  /// and `polygons` when it succeeds. It is recorded so the organization can see
  /// it and is never counted: not toward the Data API's per-minute limit, not
  /// toward its monthly allowance, and not among the requests its subscription
  /// invoices. The writes that run it are limited on their own, as this
  /// document's introduction lists. An origin no way of the activity lies near,
  /// placed as a waypoint of the activity is, on the ways it routes on, is refused
  /// with a `400` that names the isochrone input rather than a `source` path,
  /// `locations` and the origin's index, `0`, and so is an activity that has no
  /// routing, `activity`. Any other failure of the computation is a `500`, recorded as a
  /// failed `requests` with no `polygons`: the routing engine failing or refusing
  /// a request within these checks, a limit of its own included, and a polygon it
  /// answers malformed.
  public struct ZoneSource: Sendable, Hashable, Codable {
    /// The generative engine that produced the zone. `isochrones` computes a
    /// reachability polygon for an activity from a single origin point.
    public var kind: RestSchema.ZoneSourceKind
    /// The outdoor activity whose routing profile the reachability polygon is
    /// computed for (e.g. `hiking-and-trail`, `road-cycling`).
    public var activity: RestSchema.ActivitySlug
    /// Origin point the isochrone is measured from, as a `[longitude, latitude]`
    /// WGS84 coordinate pair. Longitude is bounded to -180..180 and latitude to
    /// -90..90, the same bounds every other coordinate in this contract carries.
    /// The declared bounds are the wider of the two, since one `items` schema
    /// covers both positions; the per-axis rule above is the one enforced.
    public var location: [Double]
    /// Whether `range` is measured as travel time (seconds) or travel distance
    /// (meters).
    public var range_type: RestSchema.RangeType
    /// This zone's band value: seconds when `range_type` is `time`, meters when
    /// `range_type` is `distance`. This single band drives the zone's polygon.
    /// At least 1, and at most 7,200 seconds for a `time` band and 25,000
    /// meters for a `distance` band, the ceilings the Data API's
    /// `isochrones` holds a range to, since a sourced zone's polygon is the
    /// isochrone of its source; anything else is a `400` naming `range`.
    public var range: Double
    /// Travel speed in km/h, overriding the activity's default pace. Accepted
    /// only when `range_type` is `time`, and a 400 beside `distance`: the
    /// reachable area at a given travel time is the one the stated pace covers,
    /// so a slower walker reaches less ground in the same hour. Omit to let the
    /// activity's own pace resolve at compute time, which is what a zone created
    /// without a stated pace stores. Between 0.5 and 100 km/h.
    public var speed: Double?
    /// The full set of band values this zone was created alongside, when it is
    /// one of several coverage bands. Informational: only `range` drives this
    /// zone's polygon, but `range` must be one of these values when present. A
    /// zone authored one band at a time carries no set and omits this. At most
    /// six bands, the ceiling a coverage computation is allowed to request; a
    /// longer set is refused with a validation error.
    ///
    /// The ceiling is stated here rather than declared as `maxItems`,
    /// deliberately. The TypeScript generator expands a `maxItems` of 7 or lower
    /// that has no `minItems` beside it into a union of tuples of every length up
    /// to it, so declaring this one would hand every consumer `[] | [number] |
    /// [number, number] | ...` in place of `number[]`, and no ordinary array
    /// operation would type-check against it. A ceiling of 8 or more generates a
    /// plain array and is declared, which is why a waypoint's `properties`
    /// carries `maxItems: 20` and this carries none.
    public var ranges: [Double]?
    /// Free-form provenance context, such as the matrix ranking that justified a
    /// coverage zone. Stored and echoed back verbatim; never interpreted by the
    /// API. At most 32 top-level fields and 4 KiB once serialized, since it is
    /// stored and echoed on every read of the zone.
    public var context: [String: JSONValue]?

    /// Creates a `ZoneSource` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      kind: RestSchema.ZoneSourceKind,
      activity: RestSchema.ActivitySlug,
      location: [Double],
      range_type: RestSchema.RangeType,
      range: Double,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.kind = kind
      self.activity = activity
      self.location = location
      self.range_type = range_type
      self.range = range
      self.speed = nil
      self.ranges = nil
      self.context = nil
      configure(&self)
    }

    /// Reads a `ZoneSource` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.kind = try container.decode(RestSchema.ZoneSourceKind.self, forKey: "kind")
      self.activity = try container.decode(RestSchema.ActivitySlug.self, forKey: "activity")
      self.location = try container.decode([Double].self, forKey: "location")
      self.range_type = try container.decode(RestSchema.RangeType.self, forKey: "range_type")
      self.range = try container.decode(Double.self, forKey: "range")
      self.speed = try container.decodeIfPresent(Double.self, forKey: "speed")
      self.ranges = try container.decodeIfPresent([Double].self, forKey: "ranges")
      self.context = try container.decodeIfPresent([String: JSONValue].self, forKey: "context")
    }

    /// Writes a `ZoneSource` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.kind, forKey: "kind")
      try container.encode(self.activity, forKey: "activity")
      try container.encode(self.location, forKey: "location")
      try container.encode(self.range_type, forKey: "range_type")
      try container.encode(self.range, forKey: "range")
      try container.encodeIfPresent(self.speed, forKey: "speed")
      try container.encodeIfPresent(self.ranges, forKey: "ranges")
      try container.encodeIfPresent(self.context, forKey: "context")
    }
  }
}
