/// HoveredItinerary is what a pointer over a drawn itinerary is over: the leg and the place the
/// features under it name, each nil where none names one (`geo.layers.hovered-itinerary`).
///
/// It is published because `ItinerarySegmentTable` lights the row of the leg a map's cursor is over
/// by it, and a view of `MountayaElements` stands on Geo's public API alone.
public struct HoveredItinerary: Sendable, Hashable {
  /// segmentId is the id of the first leg the features name, topmost first.
  public var segmentId: String?
  /// waypointId is the id of the first place the features name, topmost first.
  public var waypointId: String?

  /// Creates what a pointer is over, naming the leg and the place it states.
  public init(segmentId: String? = nil, waypointId: String? = nil) {
    self.segmentId = segmentId
    self.waypointId = waypointId
  }
}
