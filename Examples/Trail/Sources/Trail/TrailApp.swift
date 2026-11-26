import SwiftUI

/// TrailApp is Trail, the sample app every native Mountaya SDK ships, as the contract's
/// `sdk/trail.yaml` describes it: one portrait screen of a map with a search box over it, an
/// itinerary drawn on it with its elevation profile and its tables, and a navigation along the
/// whole itinerary, said aloud, on the device's positions or on a replay that walks the route.
///
/// It reads its settings once, as it starts, into the one value its root takes: a test hands in
/// its own through the environment it launches the app with.
@main
struct TrailApp: App {
  @State private var model = AppModel(settings: .read())

  var body: some Scene {
    WindowGroup {
      MapScreen(model: model)
    }
  }
}
