import Foundation
import MountayaClient

/// restSegment is a segment as the REST API answers one, holding what a test states and a
/// placeholder for every member the rules never read.
func restSegment(
  _ id: String = "segment",
  position: Int = 0,
  geojson: GeoJSONGeometry? = nil,
  distance: Double? = nil,
  duration: Double? = nil,
  ascent: Int? = nil,
  descent: Int? = nil,
  altitude: (min: Int?, max: Int?) = (nil, nil),
  gradient: (min: Double?, max: Double?) = (nil, nil),
  groupId: String? = nil,
  trailDifficulty: [RestSchema.TrailDifficultyInfo]? = nil,
  slope: [RestSchema.SlopeInfo]? = nil,
  surface: [RestSchema.SurfaceInfo]? = nil,
  roadAccess: [RestSchema.RoadAccessInfo]? = nil
) -> RestSchema.ItinerarySegment {
  RestSchema.ItinerarySegment(
    altitude_max: altitude.max, altitude_min: altitude.min, ascent: ascent, color: nil,
    created_at: Date(timeIntervalSince1970: 0), created_by: RestSchema.RelationToUser(id: "user"),
    descent: descent, description: nil, distance: distance, duration: duration, geojson: geojson,
    gradient_max: gradient.max, gradient_min: gradient.min, group_id: groupId, id: id,
    itinerary_id: "itinerary", mode: .linestring, name: id, position: position,
    revision: 1, road_access_info: roadAccess, slope_info: slope, speed: nil, speed_info: nil,
    start_at: nil, steps: nil, surface_info: surface, trail_difficulty_info: trailDifficulty,
    way_type_info: nil)
}

/// restWaypoint is a waypoint as the REST API answers one, holding what a test states and a
/// placeholder for every member the rules never read.
func restWaypoint(
  amenities: [String] = [],
  description: String? = nil,
  timing: RestSchema.WaypointTiming? = nil,
  contact: RestSchema.WaypointContact? = nil,
  media: RestSchema.WaypointMedia? = nil,
  properties: [RestSchema.WaypointProperty]? = nil
) -> RestSchema.ItineraryWaypoint {
  RestSchema.ItineraryWaypoint(
    amenities: amenities.map { RestSchema.WaypointAmenity(rawValue: $0) }, color: nil,
    contact: contact, created_at: Date(timeIntervalSince1970: 0),
    created_by: RestSchema.RelationToUser(id: "user"), description: description, geojson: nil,
    icon: nil, id: "waypoint", itinerary_id: "itinerary", media: media, mode: .point,
    name: nil, position: 0, properties: properties, revision: 1, timing: timing)
}

/// lineString is the LineString through the positions a test writes.
func lineString(_ positions: [Double]...) -> GeoJSONGeometry {
  .lineString(GeoJSONLineString(coordinates: positions))
}
