import MountayaClient

/// toggleAmenity is the services picked, `picked`, after a reader presses the chip of `amenity`
/// (`geo.profile.amenity-filter`): taken out of the choice where it was picked, every time it was
/// listed, and added at its end where it was not.
public func toggleAmenity(
  _ amenity: RestSchema.WaypointAmenity, in picked: [RestSchema.WaypointAmenity]
) -> [RestSchema.WaypointAmenity] {
  picked.contains { sameText($0, amenity) }
    ? picked.filter { !sameText($0, amenity) } : picked + [amenity]
}
