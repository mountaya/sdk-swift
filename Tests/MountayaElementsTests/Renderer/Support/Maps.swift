import Foundation
import MountayaClient
import MountayaElements
import MountayaGeo

/// Maps builds a map engine a view test drives with no renderer and no network: a client of a
/// publishable key, the camera given, and the geolocation given.
public enum Maps {
  /// Offline is an exchange that answers every request a 404 at once, so a client a test hands a
  /// map reaches no network: a map's read of its organization fails, and its watermark is drawn.
  public struct Offline: HTTPExchange {
    /// Creates the exchange.
    public init() {}

    /// send answers `request` a 404 at once.
    public func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      ExchangeResponse(
        status: 404, headers: ["Content-Type": "application/json"],
        body: ExchangeBody(Data(#"{"errors": [{"code": "NOT_FOUND", "message": "offline"}]}"#.utf8))
      )
    }
  }

  /// WhiteLabel is an exchange that answers every request at once with an organization holding
  /// white label, as an organization lookup answers it, so a map's read of its organization answers
  /// white label and its watermark is drawn nowhere.
  public struct WhiteLabel: HTTPExchange {
    /// Creates the exchange.
    public init() {}

    /// send answers `request` with an organization holding white label.
    public func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      ExchangeResponse(
        status: 200, headers: ["Content-Type": "application/json"],
        body: ExchangeBody(Data(Self.organization.utf8)))
    }

    /// organization is the organization the lookup answers, holding white label.
    static let organization = #"""
      {"data": {"id": "org", "name": "Alps Huts", "etag": "e", "awaiting_agreement": false,
        "created_at": "2026-03-14T09:26:53Z", "updated_at": "2026-03-14T09:26:53Z",
        "white_label": true,
        "settings": {"etag": "s",
          "default_props": {"preferred_language": "fr", "preferred_theme": "auto",
            "preferred_unit_length": "metric", "preferred_unit_pace": "per-time",
            "preferred_unit_slope": "degrees", "preferred_unit_temperature": "celsius",
            "segments_color": "#1c7ed6", "terrain": "", "terrain_variant": "light",
            "with_access_restrictions": true, "with_collection_itineraries": true,
            "with_collection_zones": true, "with_directions_control": true,
            "with_download_control": true, "with_navigation_control": true, "with_overlays": [],
            "with_overlays_control": false, "with_preferences_control": true,
            "with_profile_analysis": true, "with_profile_characteristics": true,
            "with_profile_elevation": true, "with_profile_pace_control": true,
            "with_streetview_control": false, "with_terrains": []},
          "safety_rules": {"boundaries": [], "domains": [], "require_session_token": false,
            "with_collection_itineraries": true, "with_collection_zones": true,
            "with_overlays": [], "with_overlays_control": true, "with_profile_analysis": true,
            "with_profile_elevation": true, "zoom_max": 22, "zoom_min": 0},
          "theme": {"colors": {"ui": []}}}}}
      """#
  }

  /// whiteLabel is a map whose organization holds white label, its read answered as soon as it is
  /// asked, under a key no other test's map holds.
  @MainActor
  public static func whiteLabel() throws -> MapEngine {
    MapEngine(
      client: try Mountaya(
        credential: .publishable(key: "pk_test_white_label"),
        retry: try RetryPolicy(maxRetries: 0), exchange: WhiteLabel()),
      geolocation: InertGeolocation())
  }

  /// engine is a map seen from `camera`, locating through `geolocation`.
  @MainActor
  public static func engine(
    camera: CameraPose = CameraPose(center: [6.86, 45.83], zoom: 12, pitch: 0, bearing: 0),
    geolocation: any Geolocation = InertGeolocation()
  ) throws -> MapEngine {
    MapEngine(
      client: try Mountaya(
        credential: .publishable(key: "pk_test_controls"), retry: try RetryPolicy(maxRetries: 0),
        exchange: Offline()),
      camera: camera, geolocation: geolocation)
  }

  /// pointsOfInterest is a specification drawing two concepts at the points of interest's rank,
  /// `parking` and `poi_food`, and one at an itinerary's, `lines`.
  public static let pointsOfInterest = TileSchema.TileSpecification(sources: [
    TileSchema.TileSource(
      id: "pois",
      layers: [
        TileSchema.TileLayer(
          id: "parking", key: "parking", layout: nil, paint: nil, source_layer: "parking",
          type: .circle, zoom_max: 22, zoom_min: 0),
        TileSchema.TileLayer(
          id: "food", key: "poi_food", layout: nil, paint: nil, source_layer: "poi_food",
          type: .circle, zoom_max: 22, zoom_min: 0),
        TileSchema.TileLayer(
          id: "lines", key: "lines", layout: nil, paint: nil, source_layer: "itinerary_lines",
          type: .line, zoom_max: 22, zoom_min: 0),
      ], tiles: ["https://tiles.test/pois/{z}/{x}/{y}"], type: .vector, zoom_max: 14,
      zoom_min: 0)
  ])
}

/// Located is a geolocation of a test's own: a fix it answers at once, and a standing permission.
@MainActor
public final class Located: Geolocation {
  let fix: GeolocationFix
  let standing: GeolocationPermission
  /// asked counts the fixes asked for.
  public private(set) var asked = 0

  /// Creates a geolocation answering `fix`, its permission reading `permission`.
  public init(_ fix: GeolocationFix, permission: GeolocationPermission) {
    self.fix = fix
    self.standing = permission
  }

  /// locate answers the fix, and counts the question.
  public func locate() async -> GeolocationFix {
    asked += 1
    return fix
  }

  /// permission answers the standing permission.
  public func permission() async -> GeolocationPermission { standing }
}

/// settled lets every task the main actor holds run, which is how a test waits for an engine's
/// answers to land with no clock.
@MainActor
public func settled() async {
  for _ in 0..<16 {
    await Task.yield()
  }
}
