import MountayaGeo

/// InertLocationSource is a location that never moves: it states no position at all, so every
/// position a navigation reads is one the app hands to `NavigationEngine.setPosition(_:)` itself.
///
/// It is the engine's default, for an app whose positions come from elsewhere: its own location
/// stack, a recorded track, a test. It is bound to the main actor, as every source is.
@MainActor
public final class InertLocationSource: LocationSource {
  /// Creates a source that states nothing.
  public init() {}

  /// start does nothing: no position is ever delivered.
  public func start(_ deliver: @escaping @MainActor ([Double]) throws -> Void) {}

  /// stop does nothing.
  public func stop() {}
}
