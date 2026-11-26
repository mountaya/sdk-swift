import MountayaGeo

/// hoveredLeg is the leg a hovering pointer is over, read from the features a map's hover tells
/// under it, topmost first, as `geo.layers.hovered-itinerary` reads them: the first leg a feature's
/// `segment_id` names, or nil where none names one.
func hoveredLeg(_ features: [QueriedFeature]) -> String? {
  hoveredItineraryOf(features.map(\.properties)).segmentId
}
