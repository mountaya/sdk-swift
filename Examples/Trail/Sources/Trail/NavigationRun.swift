import MountayaClient
import MountayaElements
import MountayaGeo
import MountayaNavigation

/// NavigationRun is one navigation, from Start to Stop: the engine following the whole itinerary,
/// and what it draws on the map as it goes. It is bound to the main actor, as the engine it follows
/// is.
@MainActor
final class NavigationRun {
  /// engine follows the itinerary, by its id; a view reads its `state`, which it observes.
  let engine: DeviceNavigationEngine<String>

  private let following: Task<Void, Never>

  /// Creates the run over `engine`, drawing on `map` the route it follows and following the
  /// traveller with the camera.
  init(engine: DeviceNavigationEngine<String>, map: MapEngine?) {
    self.engine = engine
    following = Task { await Self.follow(engine, on: map) }
  }

  // trail: trail.stop
  /// stop ends the navigation: the engine stops, which stops the positions and hushes the voice,
  /// and is closed, and the map stops following it.
  func stop() {
    following.cancel()
    engine.stop()
    engine.close()
  }

  // trail: trail.progress
  /// follow draws the route followed in `map`'s preview slot and eases the camera onto the
  /// traveller at each position read, until the engine is closed.
  private static func follow(_ engine: DeviceNavigationEngine<String>, on map: MapEngine?) async {
    guard let map else { return }
    var previewed: FollowedRoute?
    for await state in engine.subscribe() {
      if state.route != previewed {
        previewed = state.route
        if let route = state.route {
          map.setGeometry(.lineString(GeoJSONLineString(coordinates: route.line)), in: .preview)
        } else {
          map.clearGeometry(in: .preview)
        }
      }
      if let route = state.route, let progress = state.progress {
        try? map.ease(
          to: CameraTarget(center: positionAtMeters(route, meters: progress.along), zoom: 16))
      }
    }
    map.clearGeometry(in: .preview)
  }
}
