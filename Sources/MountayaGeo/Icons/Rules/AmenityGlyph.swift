import MountayaClient

/// amenityGlyphPrefix is the namespace an amenity's glyph name opens with, so an amenity never
/// shares a name with an icon.
public let amenityGlyphPrefix = "amenity-"

/// waypointAmenities is every amenity the contract lets a waypoint state, in the order a picker or
/// a legend walks them: sustenance first, then care, comfort, logistics, shelter and the place
/// itself.
public let waypointAmenities: [RestSchema.WaypointAmenity] = [
  .water,
  .drinks,
  .food,
  .hotMeal,
  .snacks,
  .medical,
  .firstAid,
  .toilets,
  .showers,
  .dropBag,
  .luggageStorage,
  .assistance,
  .restArea,
  .accommodation,
  .shelter,
  .camping,
  .picnic,
  .shop,
  .parking,
  .shuttle,
  .publicTransport,
  .cableCar,
  .powerCharging,
  .wifi,
  .mobileSignal,
  .waste,
  .petFriendly,
  .wheelchairAccess,
  .viewpoint,
  .timingCheckpoint,
]

/// amenityGlyph is the name of the glyph a badge for `amenity` is drawn with, `amenity-` then the
/// amenity as the wire spells it: `water` is `amenity-water`. An amenity this build does not know is
/// named the same way, and an icon set either answers the name or falls back.
public func amenityGlyph(_ amenity: RestSchema.WaypointAmenity) -> String {
  amenityGlyphPrefix + amenity.rawValue
}
