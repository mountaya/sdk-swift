import MountayaClient

/// segmentIdProperty is the property a drawn itinerary's feature names its leg by, the
/// `segmentProperty` `geo/hovered-itinerary.json` declares.
let segmentIdProperty = "segment_id"

/// waypointIdProperty is the property a drawn itinerary's feature names its place by, the
/// `waypointProperty` `geo/hovered-itinerary.json` declares.
let waypointIdProperty = "waypoint_id"

/// hoveredItineraryOf reads what a pointer is over from the properties of the features under it,
/// topmost first (`geo.layers.hovered-itinerary`): the first leg and the first place they name.
///
/// Each is read from a feature's `segment_id` and `waypoint_id` properties, as a string that is
/// not empty, and never from the feature's own id, which the itinerary's tiles leave unset. A
/// feature naming neither, or naming one by a value that is no id, gives way to the next, and a
/// feature naming both answers both: a place standing on its own leg is one answer to two
/// questions.
public func hoveredItineraryOf(_ features: [[String: JSONValue]]) -> HoveredItinerary {
  var hovered = HoveredItinerary()
  for properties in features {
    hovered.segmentId = hovered.segmentId ?? idOn(properties, named: segmentIdProperty)
    hovered.waypointId = hovered.waypointId ?? idOn(properties, named: waypointIdProperty)
  }
  return hovered
}

/// idOn is the id a feature's property names, a string that is not empty, or nil.
private func idOn(_ properties: [String: JSONValue], named name: String) -> String? {
  guard case .string(let id)? = properties[name], !id.isEmpty else { return nil }
  return id
}
