// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Activity identifier. Each activity uses a different routing profile optimized
  /// for its terrain and movement style.
  ///
  /// The REST surfaces spell these values the way they spell every shared enum:
  /// lowercased, with each underscore turned into a hyphen, so `HIKING_AND_TRAIL`
  /// here is `hiking-and-trail` there.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct ActivitySlug: RawRepresentable, Sendable, Hashable, Codable, CodingKeyRepresentable,
    ExpressibleByStringLiteral
  {
    /// Hiking and trail running on footpaths. Balanced routing that favors trails, paths, and
    /// quieter, greener ways; waypoints must lie within about 400 m of a routable path. Default
    /// speed: ~4.5 km/h.
    public static let hikingAndTrail: Self = "HIKING_AND_TRAIL"
    /// Expert trail routing on the same trail network as HIKING_AND_TRAIL, tuned for maximum reach:
    /// most-direct routing, no scenic bias, and unlimited waypoint snapping, so routes can start or
    /// end far off-network and follow very unconventional lines (only ferries are excluded). Also
    /// supports freehand line editing. Default speed: ~8 km/h.
    public static let professionalTrail: Self = "PROFESSIONAL_TRAIL"
    /// Road and path running. Fastest-preference routing that favors runnable surfaces; waypoints
    /// must lie within about 400 m of a routable way. For trail running, use HIKING_AND_TRAIL.
    /// Default speed: ~10 km/h.
    public static let running: Self = "RUNNING"
    /// Road cycling on paved roads and cycleways. Routes on the paved network with surface
    /// analysis. Default speed: ~25 km/h.
    public static let roadCycling: Self = "ROAD_CYCLING"
    /// Gravel biking on mixed-surface roads and tracks. Unavailable: the activity catalog does not
    /// list it, and a request naming it is refused, for routing, freehand line editing and analysis
    /// alike. Default speed: ~20 km/h.
    public static let gravelBike: Self = "GRAVEL_BIKE"
    /// Mountain biking on off-road trails and singletrack. Unavailable: the activity catalog does
    /// not list it, and a request naming it is refused, for routing, freehand line editing and
    /// analysis alike. Default speed: ~15 km/h.
    public static let mountainBike: Self = "MOUNTAIN_BIKE"
    /// Backcountry (off-piste) skiing. Freehand line editing only; turn-by-turn directions are not
    /// available, so you draw the route yourself. Default speed: ~4 km/h.
    public static let backcountrySkiing: Self = "BACKCOUNTRY_SKIING"
    /// Ski touring, ascending and descending off-piste. Routes on the trail network with unlimited
    /// waypoint snapping, so high-alpine points far from mapped trails still route; also supports
    /// freehand line editing. Default speed: ~4 km/h.
    public static let skiTouring: Self = "SKI_TOURING"
    /// Cross-country (nordic) skiing on groomed trails. Balanced routing that favors designated
    /// tracks; waypoints must lie within about 400 m of a routable way. Default speed: ~8 km/h.
    public static let crossCountrySkiing: Self = "CROSS_COUNTRY_SKIING"
    /// Snowshoe walking on snow-covered terrain. Routes on the trail network with relaxed waypoint
    /// snapping (up to a few km) for off-trail backcountry points; also supports freehand line
    /// editing. Default speed: ~3.5 km/h.
    public static let snowshoeWalking: Self = "SNOWSHOE_WALKING"

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
