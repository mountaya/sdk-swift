import MountayaClient

/// amenityFilter is the chips a waypoint table offers and the rows a choice of them leaves
/// (`geo.profile.amenity-filter`).
///
/// A chip stands for each service any row's place offers, once, sorted by the reader's name for it
/// (`amenityName(_:in:)`) as the reader's locale collates it, `scope.locale`, so a filter row does
/// not reshuffle between itineraries. A row stays only where its place offers every service
/// `picked`, since a reader picking water and a hot meal asks where they can have both, and with
/// none picked every row stays. Its file is `AmenityFilterRule.swift`, since `AmenityFilter.swift`
/// is the answer type's.
public func amenityFilter(
  _ rows: [ItineraryWaypointRow], picked: [RestSchema.WaypointAmenity], scope: ElementsScope
) -> AmenityFilter {
  var offered: [RestSchema.WaypointAmenity] = []
  for row in rows {
    for amenity in row.place.details?.amenities ?? []
    where !offered.contains(where: { sameText($0, amenity) }) {
      offered.append(amenity)
    }
  }
  let named = offered.enumerated().map {
    ($0.offset, $0.element, amenityName($0.element, in: scope))
  }
  let available = named.sorted { a, b in
    if localeCollated(a.2, before: b.2, languageTag: scope.locale) { return true }
    if localeCollated(b.2, before: a.2, languageTag: scope.locale) { return false }
    return a.0 < b.0
  }
  .map(\.1)
  let shown =
    picked.isEmpty
    ? rows
    : rows.filter { row in
      let services = row.place.details?.amenities ?? []
      return picked.allSatisfy { amenity in services.contains { sameText($0, amenity) } }
    }
  return AmenityFilter(available: available, shown: shown)
}
