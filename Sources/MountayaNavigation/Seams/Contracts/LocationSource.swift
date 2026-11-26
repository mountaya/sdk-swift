import MountayaGeo

/// LocationSource is where a navigation's positions come from: the platform's, a replay along the
/// route followed, none at all, or the app's own, `StreamLocationSource` over a sequence of its
/// positions among them. An engine starts it when a navigation starts and stops it when the
/// navigation stops, and hands each position it states to the engine as
/// `NavigationEngine.setPosition(_:)` takes one: `[longitude, latitude]` in degrees, with an
/// optional altitude the engine does not read.
///
/// A source never asks for location access, and never keeps reading with the screen off unless the
/// app asks it to: both are the app's decisions, with the review consequences only the app can
/// weigh, so a source reads under a permission the app already holds. It is bound to the main
/// actor, as the engine it feeds is, and delivers every position there.
@MainActor
public protocol LocationSource: AnyObject {
  /// start begins stating positions, each handed to `deliver` on the main actor until `stop()`.
  /// `deliver` throws a `PositionError` for a position that names no place, which the engine
  /// refuses and reads nothing of. Starting a source that is started does nothing.
  func start(_ deliver: @escaping @MainActor ([Double]) throws -> Void)

  /// stop ends the positions: nothing more is delivered until the next `start(_:)`. Stopping a
  /// source that is stopped does nothing.
  func stop()

  /// follow is told of each route the navigation follows, and of none, `nil`, where it stops
  /// following one: a replay walks the route it is told of, and a source that reads the platform
  /// has nothing to do with it, which is what the default does.
  func follow(_ route: FollowedRoute?)
}

extension LocationSource {
  /// follow does nothing: a source that reads the platform states where the traveller is,
  /// whatever route they follow.
  public func follow(_ route: FollowedRoute?) {}
}
