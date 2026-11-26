// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Input for generating route suggestions matching distance constraints.
  public struct SuggestionsInput: Sendable, Hashable, Codable {
    /// Activity to use for routing. BACKCOUNTRY_SKIING, GRAVEL_BIKE and MOUNTAIN_BIKE
    /// have no routing and are VALIDATION_FAILED at ["input", "activity"].
    public var activity: DataSchema.ActivitySlug
    /// Target elevation gain (ascent) in meters, a finite number, 0 or more (a
    /// negative value, NaN or Infinity is VALIDATION_FAILED at ["input", "ascent"]).
    /// A positive target ranks fresh
    /// candidates by their distance and ascent gaps combined, and drops every fresh
    /// candidate whose ascent is more than 50% above or below it, so fewer routes than
    /// `candidates`, or none, can come back with no error. Only a candidate that
    /// failed on Mountaya's side adds an error to such an answer (see `start` for
    /// when it is asked for once more, and SuggestionsResult.routes). A pinned seed
    /// is kept whatever its ascent.
    /// Example: 800.0 for 800 m of climbing.
    public var ascent: Double?
    /// Number of route candidates to generate. Must be between 1 and 10. Each
    /// candidate uses a different random seed, producing different route shapes.
    /// Example: 3 for three route options.
    public var candidates: Int
    /// Target total distance for the route in meters, greater than 0 and at most
    /// 100 km, the routing engine's own ceiling for a route and for a loop. For a
    /// point-to-point route it must also be at least the straight-line distance
    /// from `start` to `end`. Either refusal is VALIDATION_FAILED at
    /// ["input", "distance"].
    /// Example: 20000 for a 20 km route.
    ///
    /// A target, not a promise. Candidates are shaped toward it while they are being
    /// built, and the distance reported back is measured from each candidate's
    /// finished geometry, so a loop in particular may land short of it. Rank on the
    /// returned value rather than assuming the target was met.
    public var distance: Double
    /// End point as [longitude, latitude] (WGS 84): exactly two numbers, a longitude
    /// between -180 and 180 and a latitude between -90 and 90 (VALIDATION_FAILED at
    /// ["input", "end"] otherwise). When omitted, the route loops back to the start
    /// point. When provided and different from start, generates a point-to-point
    /// route shaped to meet the target distance.
    /// Example: [6.7113, 45.8929] (Saint-Gervais-les-Bains).
    public var end: [Double]?
    /// Number of route shaping points (2-10, default 5). Higher values produce
    /// rounder, more circular loops. Only applies to loop routes.
    /// Example: 5 (default). Higher values (8-10) produce rounder loops.
    public var points: Int?
    /// Optional directives to pin specific seeds into the result (include) and/or
    /// avoid specific seeds when generating fresh candidates (exclude). Useful to
    /// reproduce previously-returned routes, discover new variations different
    /// from ones already seen, or both in one call. See SuggestionSeedsInput for
    /// details.
    public var seeds: DataSchema.SuggestionSeedsInput?
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
    /// Starting point as [longitude, latitude] (WGS 84): exactly two numbers, a
    /// longitude between -180 and 180 and a latitude between -90 and 90
    /// (VALIDATION_FAILED at ["input", "start"] otherwise).
    /// Example: [6.8712, 45.9231] (Chamonix).
    ///
    /// When no hazard-free candidate can be generated from the given points, the
    /// request fails with VALIDATION_FAILED at ["input", "start"] rather than
    /// returning one that crosses something, and so does a request for which no
    /// candidate can be routed at all because the routing engine finds no routable
    /// point or no route for any of them. A candidate that failed on Mountaya's side
    /// is asked for once more when the answer would otherwise fall short or fail
    /// because of it and the request's time budget leaves room, and one that
    /// answers then leaves these answers as they are. When no candidate survives
    /// and one of them failed on Mountaya's side, the request is INTERNAL_ERROR
    /// instead, whichever candidate finished first.
    public var start: [Double]

    /// Creates a `SuggestionsInput` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      activity: DataSchema.ActivitySlug,
      candidates: Int,
      distance: Double,
      start: [Double],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.activity = activity
      self.ascent = nil
      self.candidates = candidates
      self.distance = distance
      self.end = nil
      self.points = nil
      self.seeds = nil
      self.speed = nil
      self.start = start
      configure(&self)
    }

    /// Reads a `SuggestionsInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.activity = try container.decode(DataSchema.ActivitySlug.self, forKey: "activity")
      self.ascent = try container.decodeIfPresent(Double.self, forKey: "ascent")
      self.candidates = try container.decode(Int.self, forKey: "candidates")
      self.distance = try container.decode(Double.self, forKey: "distance")
      self.end = try container.decodeIfPresent([Double].self, forKey: "end")
      self.points = try container.decodeIfPresent(Int.self, forKey: "points")
      self.seeds = try container.decodeIfPresent(
        DataSchema.SuggestionSeedsInput.self, forKey: "seeds")
      self.speed = try container.decodeIfPresent(Double.self, forKey: "speed")
      self.start = try container.decode([Double].self, forKey: "start")
    }

    /// Writes a `SuggestionsInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.activity, forKey: "activity")
      try container.encodeIfPresent(self.ascent, forKey: "ascent")
      try container.encode(self.candidates, forKey: "candidates")
      try container.encode(self.distance, forKey: "distance")
      try container.encodeIfPresent(self.end, forKey: "end")
      try container.encodeIfPresent(self.points, forKey: "points")
      try container.encodeIfPresent(self.seeds, forKey: "seeds")
      try container.encodeIfPresent(self.speed, forKey: "speed")
      try container.encode(self.start, forKey: "start")
    }
  }
}
