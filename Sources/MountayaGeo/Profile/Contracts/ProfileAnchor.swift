/// ProfileAnchor is what a profile's elevation scale is measured from (`geo.profile.domain`).
public enum ProfileAnchor: String, CaseIterable, Sendable {
  /// route frames the itinerary's own extent, whatever window is drawn, so a zoomed curve keeps the
  /// height it had.
  case route
  /// seaLevel frames the itinerary's extent and then moves the floor to zero, its ceiling kept, so
  /// two itineraries drawn side by side are comparable.
  case seaLevel = "sea-level"
  /// window frames the stretch the window drawn holds, so zooming into a section rescales to its
  /// own relief.
  case window
}
