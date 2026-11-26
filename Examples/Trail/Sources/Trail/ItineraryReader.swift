import Foundation
import MountayaClient
import MountayaElements
import MountayaGeo

/// ItineraryReader is where Trail's itinerary comes from, the source its one
/// `ItineraryResourceCache` reads through: the itinerary `MOUNTAYA_ITINERARY_ID` names, read with
/// `getItinerary`, or, for its own id, the demo itinerary, which needs no network. It keeps each
/// itinerary it answered, which the map draws and the navigation follows. It is bound to the main
/// actor, as the cache it answers is.
@MainActor
final class ItineraryReader {
  /// demo is the demo itinerary, the app's copy of the contract's `sdk/trail/itinerary.json`,
  /// decoded as the `ItineraryWithDetails` it is, or why it could not be read.
  let demo: Result<RestSchema.ItineraryWithDetails, any Error>

  private let mountaya: Mountaya?
  private var answered: [String: RestSchema.ItineraryWithDetails] = [:]

  /// Creates the source over `mountaya`, the app's client, nil where no key is set, reading the
  /// demo from `bundle`.
  init(mountaya: Mountaya?, bundle: Bundle = .main) {
    self.mountaya = mountaya
    demo = Result {
      guard let url = bundle.url(forResource: "itinerary", withExtension: "json") else {
        throw CocoaError(.fileNoSuchFile)
      }
      return try JSONDecoder().decode(
        RestSchema.ItineraryWithDetails.self, from: Data(contentsOf: url))
    }
  }

  /// demoId is the demo itinerary's own id, which the app shows where no itinerary id is set.
  var demoId: String? {
    try? demo.get().id
  }

  // trail: trail.itinerary
  /// read answers the itinerary of id `id`: the demo for its own id, and any other read with
  /// `getItinerary` through the client, which needs the publishable key.
  func read(_ id: String, surface: RestSchema.ReadSurface?) async throws
    -> RestSchema.ItineraryWithDetails
  {
    if let demo = try? demo.get(), demo.id == id {
      answered[id] = demo
      return demo
    }
    guard let mountaya else {
      throw NoItinerary(id: id)
    }
    let read = try await mountaya.studio.itineraries.getItinerary(
      itinerary_id: id, query: .init { $0.surface = surface }
    ).data
    answered[id] = read
    return read
  }

  /// held is the itinerary of id `id` as it was last answered, nil before it was read.
  func held(_ id: String) -> RestSchema.ItineraryWithDetails? {
    answered[id]
  }

  // trail: trail.navigation
  /// route is the one route Start follows: the whole itinerary, its segments joined end to end by
  /// `readItineraryRoute`, each waypoint passed on the way a `waypoint` maneuver.
  func route(_ id: String) async throws -> NavigationRoute {
    let itinerary: RestSchema.ItineraryWithDetails
    if let held = answered[id] {
      itinerary = held
    } else {
      itinerary = try await read(id, surface: nil)
    }
    guard let route = readItineraryRoute(itinerary.segments, waypoints: itinerary.waypoints)
    else { throw NoItinerary(id: id) }
    return route
  }

  // trail: trail.itinerary
  /// draw draws `itinerary` on `map`: its segments as one line, each in its own colour, ranked
  /// where the layer registry ranks an itinerary's line, and a marker on each of its places.
  static func draw(_ itinerary: RestSchema.ItineraryWithDetails, on map: MapEngine) {
    let segments = itinerary.segments.compactMap { segment -> GeoJSONFeature? in
      guard let geometry = segment.geojson else { return nil }
      return GeoJSONFeature(
        geometry: geometry, properties: ["color": .string(segment.color ?? "#2f80ed")])
    }
    map.addSource(
      MapSource(id: drawn, kind: .geoJson(GeoJSONFeatureCollection(features: segments))))
    map.addLayer(
      MapLayer(
        id: drawn, type: .line, source: drawn, rank: LayerRank.itineraryLine.rank,
        paint: ["line-color": ["get", "color"], "line-width": 4],
        layout: ["line-cap": "round", "line-join": "round"]))
    for waypoint in itinerary.waypoints {
      guard case .point(let point)? = waypoint.geojson, point.coordinates.count >= 2 else {
        continue
      }
      try? map.addMarker(
        MapMarker(
          id: "\(drawn)-\(waypoint.id)", position: Array(point.coordinates.prefix(2)),
          label: waypoint.name))
    }
  }

  /// frame frames `itinerary` on `map`, clear of the search box above and the sheet below.
  static func frame(_ itinerary: RestSchema.ItineraryWithDetails, on map: MapEngine) {
    guard let bounds = itineraryBounds(itinerary.segments) else { return }
    try? map.fitBounds(
      bounds,
      with: CameraFit(padding: PixelPadding(top: 120, right: 48, bottom: 380, left: 48)))
  }

  /// drawn is the id of the source and the layer the itinerary is drawn with, and the start of
  /// its markers' ids.
  static let drawn = "trail-itinerary"
}

/// NoItinerary is an itinerary Trail cannot read or follow: one no key reads, or one holding no
/// segment with a line.
struct NoItinerary: Error, CustomStringConvertible {
  /// id is the itinerary's id.
  let id: String

  var description: String {
    "The itinerary \(id) cannot be read or holds no line to follow."
  }
}
