/// NavigationState is what a navigation reports: the status it is in, the route it follows, where
/// the traveller stands on it, and why the last route request it acted on failed. A renderer draws
/// it and decides none of it, so a Mountaya map and a host's own screen show one navigation.
///
/// Two are equal where every member is, a route and a reading by what they hold, so an engine
/// reports a state only where it differs from the one it holds. A state that holds the route it
/// held compares the route's storage alone, never its vertices.
public struct NavigationState: Sendable, Hashable {
  /// status is the status the navigation is in.
  public var status: NavigationStatus
  /// route is the route followed, or nil where the navigation holds none.
  public var route: FollowedRoute?
  /// progress is where the traveller stands on `route`, from the last position read on it, or nil
  /// before any.
  public var progress: NavigationProgress?
  /// error is why the last route request the navigation acted on failed, or nil where none did
  /// since the last start.
  public var error: NavigationError?

  /// Creates a state from its status, and the route, the reading and the error it holds, none by
  /// default.
  public init(
    status: NavigationStatus, route: FollowedRoute? = nil, progress: NavigationProgress? = nil,
    error: NavigationError? = nil
  ) {
    self.status = status
    self.route = route
    self.progress = progress
    self.error = error
  }

  /// idle is the state every navigation starts in, and where a stop leaves it: `idle`, holding no
  /// route, no reading and no error.
  public static let idle = NavigationState(status: .idle)
}
