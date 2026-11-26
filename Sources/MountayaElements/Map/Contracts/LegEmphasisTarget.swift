import MountayaClient

/// LegEmphasisTarget is the map whose emphasis slot an element lights the leg a reader points at on
/// (`map.profile.emphasis`): the slot calls a map answers. `MapEngine` is one; a map of an app's
/// own, or a test's double recording what an element writes, is another.
///
/// It is bound to the main actor, as every map is.
@MainActor
public protocol LegEmphasisTarget: AnyObject {
  /// setGeometry draws `geometry` in `slot`, in `color`, the slot's own where it is nil, as
  /// `MapEngine` draws one (`map.geometry.slots`).
  func setGeometry(_ geometry: GeoJSONGeometry?, in slot: GeometrySlot, color: String?)

  /// clearGeometry takes `slot` down, giving it back its own colour.
  func clearGeometry(in slot: GeometrySlot)
}
