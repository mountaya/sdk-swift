import MountayaClient

extension RestSchema.ManeuverType {
  /// waypoint is passing a waypoint on the way: the arrival of an itinerary's segment that another
  /// segment follows, as `readItineraryRoute(_:waypoints:)` says it, which `stepInstruction(_:)`
  /// says with the waypoint's name (`geo.navigation.itinerary-route`).
  ///
  /// It is the navigation vocabulary's own, and no surface writes it: a step a surface sends with
  /// this spelling reads as `unknown` (`geo.navigation.steps`).
  public static let waypoint: Self = "waypoint"
}
