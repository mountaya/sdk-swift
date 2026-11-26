// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Unique identifier for an outdoor activity type. Determines routing profiles,
  /// surface analysis, and available capabilities.
  ///
  /// The notes below summarize each one. What an activity actually supports is
  /// reported per activity by `Activity.capabilities`, which is the answer to
  /// branch on: it says whether directions, freehand line editing and surface
  /// analysis are available, and it is the value the server checks a request
  /// against.
  ///
  /// The Data API spells the same activities in SCREAMING_SNAKE, and the mapping
  /// is the one every shared enum uses: `HIKING_AND_TRAIL` there is
  /// `hiking-and-trail` here, lowercased with each underscore turned into a
  /// hyphen.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct ActivitySlug: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// Hiking and trail running on footpaths. Balanced routing that favors trails, paths, and
    /// quieter, greener ways; waypoints must lie within about 400 m of a routable path. Default
    /// speed: ~4.5 km/h.
    public static let hikingAndTrail: Self = "hiking-and-trail"
    /// Expert trail routing on the same trail network as hiking-and-trail, tuned for maximum reach:
    /// most-direct routing, no scenic bias, and unlimited waypoint snapping, so routes can start or
    /// end far off-network and follow very unconventional lines (only ferries are excluded). Also
    /// supports freehand line editing. Default speed: ~8 km/h.
    public static let professionalTrail: Self = "professional-trail"
    /// Road and path running. Fastest-preference routing that favors runnable surfaces; waypoints
    /// must lie within about 400 m of a routable way. For trail running, use hiking-and-trail.
    /// Default speed: ~10 km/h.
    public static let running: Self = "running"
    /// Road cycling on paved roads and cycleways. Routes on the paved network with surface
    /// analysis. Default speed: ~25 km/h.
    public static let roadCycling: Self = "road-cycling"
    /// Gravel biking on mixed-surface roads and tracks. Unavailable: the activity catalog does not
    /// list it, and a request naming it is refused, for routing, freehand line editing and analysis
    /// alike. Default speed: ~20 km/h.
    public static let gravelBike: Self = "gravel-bike"
    /// Mountain biking on off-road trails and singletrack. Unavailable: the activity catalog does
    /// not list it, and a request naming it is refused, for routing, freehand line editing and
    /// analysis alike. Default speed: ~15 km/h.
    public static let mountainBike: Self = "mountain-bike"
    /// Backcountry (off-piste) skiing. Freehand line editing only; turn-by-turn directions are not
    /// available, so you draw the route yourself. Default speed: ~4 km/h.
    public static let backcountrySkiing: Self = "backcountry-skiing"
    /// Ski touring, ascending and descending off-piste. Routes on the trail network with unlimited
    /// waypoint snapping, so high-alpine points far from mapped trails still route; also supports
    /// freehand line editing. Default speed: ~4 km/h.
    public static let skiTouring: Self = "ski-touring"
    /// Cross-country (nordic) skiing on groomed trails. Balanced routing that favors designated
    /// tracks; waypoints must lie within about 400 m of a routable way. Default speed: ~8 km/h.
    public static let crossCountrySkiing: Self = "cross-country-skiing"
    /// Snowshoe walking on snow-covered terrain. Routes on the trail network with relaxed waypoint
    /// snapping (up to a few km) for off-trail backcountry points; also supports freehand line
    /// editing. Default speed: ~3.5 km/h.
    public static let snowshoeWalking: Self = "snowshoe-walking"

    /// rawValue is the value as the wire spells it.
    public let rawValue: String

    /// Creates a value from its wire spelling, which may be one this build has never seen.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// Creates a value from a string literal, which is its wire spelling.
    public init(stringLiteral value: String) {
      self.rawValue = value
    }

    /// codingKey is the value as an object's key, where the contract keys a map by it.
    public var codingKey: any CodingKey {
      WireKey(stringValue: rawValue)
    }

    /// Creates a value from an object's key.
    public init?<Key: CodingKey>(codingKey: Key) {
      self.rawValue = codingKey.stringValue
    }

    /// Reads the value from its wire spelling.
    public init(from decoder: any Decoder) throws {
      self.rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    /// Writes the value as the wire spells it.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }
  }
}
