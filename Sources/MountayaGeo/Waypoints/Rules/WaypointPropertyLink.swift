import MountayaClient

/// waypointPropertyLink is the address a renderer may anchor a place's custom field by
/// (`geo.profile.waypoint-property-value`): its value past the white space at its ends, only where
/// the field is declared a `url` and that value is a web address (`isWebAddress(_:)`), else nil.
///
/// The declared format is not enough on its own: a renderer told a value is a link anchors it, so
/// a `url` field holding `javascript:` would be a script a reader taps. The format says what the
/// author meant and the value what it is, and a link needs both.
public func waypointPropertyLink(_ property: WaypointDetails.Property) -> String? {
  guard let format = property.format, sameText(format, .url) else {
    return nil
  }
  let address = trimWhiteSpace(property.value)
  return isWebAddress(address) ? address : nil
}
