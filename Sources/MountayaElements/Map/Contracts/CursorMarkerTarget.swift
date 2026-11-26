/// CursorMarkerTarget is the map an element's cursor marker is pinned to
/// (`map.profile.cursor-marker`): the three marker calls a map answers. `MapEngine` is one; a map
/// of an app's own, or a test's double recording what an element writes, is another.
///
/// It is bound to the main actor, as every map is.
@MainActor
public protocol CursorMarkerTarget: AnyObject {
  /// addMarker pins `marker` in place of the one pinned under its id, as `MapEngine` pins one.
  func addMarker(_ marker: MapMarker) throws(MapError)

  /// editMarker changes the marker pinned under `id`, each member given replacing the one held,
  /// and throws a `MapError` of kind `markerNotFound` where none is pinned under it.
  func editMarker(
    _ id: String, position: [Double]?, color: String?, glyph: String?, label: String?
  ) throws(MapError)

  /// removeMarker takes off the marker pinned under `id`, where one is.
  func removeMarker(_ id: String)
}
