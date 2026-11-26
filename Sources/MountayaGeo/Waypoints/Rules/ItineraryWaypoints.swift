import Foundation
import MountayaClient

/// itineraryWaypoints is an itinerary's waypoints as an element draws them, its places, in chain
/// order, by their `position`, two at one position in the order they are listed
/// (`geo.data.itinerary-waypoints`).
///
/// Each stands at the first point its geometry holds, a Point at any depth of the collections it
/// nests in whose longitude and latitude name a place, read as `[longitude, latitude]` with its
/// altitude left out, and a waypoint whose geometry holds no such point, or that has none, is left
/// out, since there is nowhere to draw it. Its name, its colour and its icon, the glyph it is
/// pinned with, are carried as the wire states them.
///
/// Its details are carried only where a member holds something: the services it lists; its note;
/// its cut-off where it names an instant, a date whose seconds are not finite naming none, and its
/// planned stop; each member of its contact the wire states, an address as the text the wire answers
/// it as; its photos, each with its caption where it states one, and its links; and its fields in the order they are shown, each with its
/// format where it states one. A null and an absent member are one, and a list left empty, a block
/// left with nothing and details left with nothing read as none.
public func itineraryWaypoints(_ waypoints: [RestSchema.ItineraryWaypoint]) -> [ItineraryPlace] {
  inChainOrder(waypoints, position: \.position).compactMap { waypoint in
    guard let lngLat = firstPoint(waypoint.geojson) else { return nil }
    return ItineraryPlace(
      id: waypoint.id,
      lngLat: lngLat,
      name: waypoint.name,
      color: waypoint.color,
      glyph: waypoint.icon,
      details: detailsOf(waypoint)
    )
  }
}

/// The first point a geometry holds whose longitude and latitude name a place, at any depth of the
/// collections it nests in, as `[longitude, latitude]`, or nil where it holds none.
private func firstPoint(_ geometry: GeoJSONGeometry?) -> [Double]? {
  switch geometry {
  case .point(let point)?:
    let position = point.coordinates
    return namesPlace(position) ? [position[0], position[1]] : nil
  case .geometryCollection(let collection)?:
    for member in collection.geometries {
      if let found = firstPoint(member) { return found }
    }
    return nil
  default:
    return nil
  }
}

/// What a waypoint says about its place, or nil where it says nothing.
private func detailsOf(_ waypoint: RestSchema.ItineraryWaypoint) -> WaypointDetails? {
  let amenities = waypoint.amenities
  let details = WaypointDetails(
    amenities: amenities.isEmpty ? nil : amenities,
    description: waypoint.description,
    timing: timingOf(waypoint.timing),
    contact: contactOf(waypoint.contact),
    media: mediaOf(waypoint.media),
    properties: propertiesOf(waypoint.properties)
  )
  let saysNothing =
    details.amenities == nil && details.description == nil && details.timing == nil
    && details.contact == nil && details.media == nil && details.properties == nil
  return saysNothing ? nil : details
}

/// A waypoint's timing, its cut-off only where it names an instant, or nil where it holds neither.
private func timingOf(_ timing: RestSchema.WaypointTiming?) -> WaypointDetails.Timing? {
  guard let timing else { return nil }
  // A date whose seconds are not finite names no instant.
  let cutoffAt = (timing.cutoff_at ?? nil).flatMap {
    $0.timeIntervalSinceReferenceDate.isFinite ? $0 : nil
  }
  let stopDuration = timing.stop_duration ?? nil
  guard cutoffAt != nil || stopDuration != nil else { return nil }
  return WaypointDetails.Timing(cutoffAt: cutoffAt, stopDuration: stopDuration)
}

/// A waypoint's contact, each member the wire states, or nil where it states none.
private func contactOf(_ contact: RestSchema.WaypointContact?) -> WaypointDetails.Contact? {
  guard let contact else { return nil }
  let read = WaypointDetails.Contact(
    address: contact.address ?? nil,
    bookingUrl: (contact.booking_url ?? nil)?.text,
    email: contact.email ?? nil,
    openingHours: contact.opening_hours ?? nil,
    phone: contact.phone ?? nil,
    website: (contact.website ?? nil)?.text
  )
  let statesNothing =
    read.address == nil && read.bookingUrl == nil && read.email == nil
    && read.openingHours == nil && read.phone == nil && read.website == nil
  return statesNothing ? nil : read
}

/// A waypoint's photos and links, each list nil where it holds none, or nil where both are.
private func mediaOf(_ media: RestSchema.WaypointMedia?) -> WaypointDetails.Media? {
  guard let media else { return nil }
  let photos = ((media.photos ?? nil) ?? []).map {
    WaypointDetails.Photo(url: $0.url.text, caption: $0.caption ?? nil)
  }
  let links = ((media.links ?? nil) ?? []).map {
    WaypointDetails.Link(label: $0.label, url: $0.url.text)
  }
  guard !photos.isEmpty || !links.isEmpty else { return nil }
  return WaypointDetails.Media(
    photos: photos.isEmpty ? nil : photos, links: links.isEmpty ? nil : links)
}

/// A waypoint's fields in the order they are shown, or nil where it has none.
private func propertiesOf(_ properties: [RestSchema.WaypointProperty]?)
  -> [WaypointDetails.Property]?
{
  let fields = (properties ?? []).map {
    WaypointDetails.Property(
      key: $0.key, label: $0.label, value: $0.value, format: $0.format ?? nil)
  }
  return fields.isEmpty ? nil : fields
}
