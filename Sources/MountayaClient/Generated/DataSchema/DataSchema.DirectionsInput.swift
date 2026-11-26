// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Input for computing directions between waypoints.
  public struct DirectionsInput: Sendable, Hashable, Codable {
    /// Activity to use for routing.
    public var activity: DataSchema.ActivitySlug
    /// Ordered list of waypoints as [longitude, latitude] coordinate pairs (WGS 84).
    /// Must contain between 2 and 45 waypoints, and the straight-line polyline
    /// through them, waypoint to waypoint, may be at most 100 km long; either refusal
    /// is VALIDATION_FAILED at ["input", "waypoints"]. Each waypoint is exactly two
    /// numbers, a longitude between -180 and 180 and a latitude between -90 and 90,
    /// and one that is not is VALIDATION_FAILED at ["input", "waypoints", i]. The
    /// count, the length and `speed` are checked before any single waypoint, so an
    /// out-of-range waypoint that stretches the polyline past 100 km is first reported
    /// at ["input", "waypoints"]. Prefer the fewest waypoints that pin the intended
    /// route.
    ///
    /// A waypoint that no routable way reaches for the activity, or waypoints no
    /// route connects, is refused with VALIDATION_FAILED at ["input", "waypoints"].
    /// A request within the 100 km bound on the waypoints' line that the routing
    /// engine still measures past it is VALIDATION_FAILED at ["input"], and its
    /// message is the engine's own, in English whatever the Accept-Language header
    /// asks for. Those are the routing engine's only answers that are the caller's
    /// to fix: any other failure of the engine, its refusal of a parameter this API
    /// built included, is INTERNAL_ERROR.
    /// Example: [[6.8712, 45.9231], [6.9271, 45.9822]] (Chamonix to Argentière).
    public var waypoints: [[Double]]
    /// Travel speed in km/h on LEVEL ground, a finite number greater than 0 (anything
    /// else, NaN and Infinity included, is VALIDATION_FAILED at ["input", "speed"]).
    /// When provided, it replaces the
    /// selected activity's default as the flat pace the travel-time model starts
    /// from.
    ///
    /// It is not the speed the route is travelled at: the model resolves a speed per
    /// stretch from this pace and the ground (slower on a climb, faster on a
    /// descent, and slower again over a coarse surface or a technical trail), caps
    /// each stretch at the activity's maximum speed (see SpeedInfo), and integrates
    /// the duration over that. Read `analysis.speedInfo` for what each stretch
    /// resolved to. While no stretch reaches that cap, duration is inversely
    /// proportional to this figure, so halving it doubles the duration.
    /// Example: 4.5 for hiking, 25.0 for road cycling.
    public var speed: Double?
    /// Hazards to route around. Omitted or empty routes normally.
    ///
    /// Naming a hazard costs a second routing round-trip only when the first route
    /// actually crosses it. Avoidance is best-effort: read `avoidance` on the result
    /// to learn whether it was applied, and the analysis `advisories` to learn what
    /// the returned route still crosses. A waypoint placed ON a hazardous way cannot
    /// be routed around and yields `NO_ROUTE`. A re-route that fails on Mountaya's
    /// side keeps the first route as `NO_ROUTE` too, and the field then carries an
    /// INTERNAL_ERROR entry in `errors` beside its data; such a request is recorded
    /// as a failure (5xx), so it counts toward neither the monthly allowance nor an
    /// invoice.
    ///
    /// Routing around a hazard needs the per-stretch hazard data the routing engine
    /// returns with a route, and a SKI_TOURING, CROSS_COUNTRY_SKIING or
    /// SNOWSHOE_WALKING route carries none. For those three, `avoidance` is always
    /// NOT_NEEDED and the advisories alone report what the route crosses.
    public var avoid: [DataSchema.RouteHazard]?

    /// Creates a `DirectionsInput` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      activity: DataSchema.ActivitySlug,
      waypoints: [[Double]],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.activity = activity
      self.waypoints = waypoints
      self.speed = nil
      self.avoid = nil
      configure(&self)
    }

    /// Reads a `DirectionsInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.activity = try container.decode(DataSchema.ActivitySlug.self, forKey: "activity")
      self.waypoints = try container.decode([[Double]].self, forKey: "waypoints")
      self.speed = try container.decodeIfPresent(Double.self, forKey: "speed")
      self.avoid = try container.decodeIfPresent([DataSchema.RouteHazard].self, forKey: "avoid")
    }

    /// Writes a `DirectionsInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.activity, forKey: "activity")
      try container.encode(self.waypoints, forKey: "waypoints")
      try container.encodeIfPresent(self.speed, forKey: "speed")
      try container.encodeIfPresent(self.avoid, forKey: "avoid")
    }
  }
}
