import Foundation
import MountayaClient
import MountayaGeo

/// Itineraries builds the itinerary a data element's test draws, read through a cache that answers
/// at once with no network: two legs, a climb from 1,000 m to a col at 1,400 m and a descent to
/// 1,100 m, each about 1.1 km, and three places along them, a hut with services and a cut-off, the
/// col, and an unnamed spring.
public enum Itineraries {
  /// climb is the first leg's line, due north from 6 E 45 N, its altitude every 555.97 m.
  public static let climb: [[Double]] = [[6, 45, 1_000], [6, 45.005, 1_200], [6, 45.01, 1_400]]
  /// descent is the second leg's line, on north from the col.
  public static let descent: [[Double]] = [
    [6, 45.01, 1_400], [6, 45.015, 1_250], [6, 45.02, 1_100],
  ]

  /// itinerary is the itinerary the REST API answers.
  public static let itinerary = RestSchema.ItineraryWithDetails(
    activity_id: "hiking", ascent: nil,
    count: RestSchema.ItineraryCount(groups: 0, segments: 2, waypoints: 3),
    created_at: Date(timeIntervalSince1970: 0), created_by: RestSchema.RelationToUser(id: "user"),
    description: nil, distance: nil, id: "itin_test", is_private: false, is_verified: false,
    name: "Col", organization_id: nil, etag: "etag", revision: 1, status: .draft,
    updated_at: Date(timeIntervalSince1970: 0), groups: [], has_unpublished_changes: false,
    published_at: nil,
    segments: [
      segment("climb", position: 0, line: climb, color: "#e8590c"),
      segment("descent", position: 1, line: descent, color: nil),
    ],
    waypoints: [
      place(
        "hut", position: 0, at: [6, 45.005], name: "Refuge", icon: "hut",
        amenities: ["water", "hot-meal", "toilets", "first-aid", "showers"],
        cutoff: Date(timeIntervalSince1970: 1_788_000_000)),
      place("col", position: 1, at: [6, 45.01], name: "Col", icon: "mountain"),
      place("spring", position: 2, at: [6, 45.015], name: nil, icon: nil),
    ])

  /// flat is the same itinerary with no altitude: each vertex a longitude and a latitude alone.
  public static var flat: RestSchema.ItineraryWithDetails {
    var flat = itinerary
    flat.segments = [
      segment("climb", position: 0, line: climb.map { Array($0.prefix(2)) }, color: "#e8590c"),
      segment("descent", position: 1, line: descent.map { Array($0.prefix(2)) }, color: nil),
    ]
    return flat
  }

  /// Unreadable is what a source that cannot read the itinerary throws.
  public struct Unreadable: Error, Equatable {}

  /// cache is a cache over a source answering `itinerary` for every id, at once.
  @MainActor
  public static func cache(_ answered: RestSchema.ItineraryWithDetails = itinerary)
    -> ItineraryResourceCache
  {
    ItineraryResourceCache { _, _ in answered }
  }

  /// unreadable is a cache over a source that throws `Unreadable` for every id.
  @MainActor
  public static func unreadable() -> ItineraryResourceCache {
    ItineraryResourceCache { _, _ in throw Unreadable() }
  }

  /// resolved is the itinerary's projections, as an element reads them.
  public static var resolved: ResolvedItinerary { ResolvedItinerary(itinerary) }

  private static func segment(
    _ id: String, position: Int, line: [[Double]], color: String?
  ) -> RestSchema.ItinerarySegment {
    RestSchema.ItinerarySegment(
      altitude_max: nil, altitude_min: nil, ascent: nil, color: color,
      created_at: Date(timeIntervalSince1970: 0), created_by: RestSchema.RelationToUser(id: "user"),
      descent: nil, description: nil, distance: nil, duration: nil,
      geojson: .lineString(GeoJSONLineString(coordinates: line)), gradient_max: nil,
      gradient_min: nil, group_id: nil, id: id, itinerary_id: "itin_test",
      mode: .linestring, name: id == "climb" ? "Climb" : "Descent", position: position,
      revision: 1, road_access_info: nil, slope_info: nil, speed: nil, speed_info: nil,
      start_at: nil, steps: nil, surface_info: nil, trail_difficulty_info: nil, way_type_info: nil)
  }

  private static func place(
    _ id: String, position: Int, at point: [Double], name: String?,
    icon: RestSchema.WaypointIcon?, amenities: [RestSchema.WaypointAmenity] = [],
    cutoff: Date? = nil
  ) -> RestSchema.ItineraryWaypoint {
    RestSchema.ItineraryWaypoint(
      amenities: amenities, color: nil, contact: nil, created_at: Date(timeIntervalSince1970: 0),
      created_by: RestSchema.RelationToUser(id: "user"), description: nil,
      geojson: .point(GeoJSONPoint(coordinates: point)), icon: icon, id: id,
      itinerary_id: "itin_test", media: nil, mode: .poi, name: name,
      position: position, properties: nil, revision: 1,
      timing: cutoff.map { instant in RestSchema.WaypointTiming { $0.cutoff_at = instant } })
  }
}
