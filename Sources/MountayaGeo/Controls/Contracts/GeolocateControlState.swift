/// GeolocateControlState is what a locate control shows (`geo.controls.geolocate-state`): whether a
/// fix it asked for is still out, whether location stands refused, and whether a press has a map
/// to ask.
public struct GeolocateControlState: Sendable, Hashable {
  /// isBusy is whether a fix the control asked for is still out: from a press until every fix it
  /// asked for settles, whatever map it stands over meanwhile.
  public var isBusy: Bool
  /// isBlocked is whether the control says location is blocked: while the latest read of the
  /// standing permission, through the map it stands over, answers refused.
  public var isBlocked: Bool
  /// isLive is whether a press has a map to ask, which no refusal changes.
  public var isLive: Bool

  /// Creates what a control shows.
  public init(isBusy: Bool = false, isBlocked: Bool = false, isLive: Bool = false) {
    self.isBusy = isBusy
    self.isBlocked = isBlocked
    self.isLive = isLive
  }
}
