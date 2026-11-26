import Foundation
import MountayaClient

/// defaultWaypointTableColumns is the columns a waypoint table draws where its caller names none,
/// the `defaultColumns` `geo/profile-waypoint-table-cells.json` declares: the place, its shape, how
/// far, how much climb, and what is there.
public let defaultWaypointTableColumns: [WaypointTableColumn] = [
  .waypoint, .profile, .distance, .elevation, .amenities,
]

/// waypointRowCell is what `column` of a waypoint table states about `row`'s place
/// (`geo.profile.waypoint-table-cells`): its glyph, its own where `glyphs`, the set the table marks
/// places with, draws it and `waypointFallbackGlyph` otherwise, and its name; the whole
/// itinerary's sparkline with the stretch reaching it lit; its running distance; the climb and loss
/// since the previous place; its altitude; its services in the order it states them; its cut-off
/// only through `formatCutoffAt`, since an instant needs a time zone only the caller holds; and its
/// fields, each written by its declared format for `units`
/// (`waypointPropertyValue(_:units:formatInstant:)`), with the address a link field is anchored by.
/// Its file is `WaypointRowCellRule.swift`, since `WaypointRowCell.swift` is the answer type's.
public func waypointRowCell(
  _ row: ItineraryWaypointRow,
  column: WaypointTableColumn,
  glyphs: GlyphSet,
  units: UnitPreferences,
  formatCutoffAt: ((Date) -> String)? = nil
) -> WaypointRowCell {
  let details = row.place.details
  let metrics = row.metrics
  switch column {
  case .waypoint:
    let own = row.place.glyph?.rawValue
    let glyph = own.flatMap { glyphs.markup[$0] == nil ? nil : $0 } ?? waypointFallbackGlyph
    return .waypoint(glyph: glyph, name: row.place.name)
  case .profile:
    return .profile(lit: ProfileRange(from: row.from, to: row.to))
  case .distance:
    return .distance(total: metrics.distance)
  case .elevation:
    return .elevation(ascent: metrics.sectionAscent, descent: metrics.sectionDescent)
  case .altitude:
    return .altitude(metrics.altitude)
  case .amenities:
    return .amenities(details?.amenities ?? [])
  case .cutoff:
    guard let cutoffAt = details?.timing?.cutoffAt, let formatCutoffAt else {
      return .cutoff(moment: nil)
    }
    return .cutoff(moment: formatCutoffAt(cutoffAt))
  case .properties:
    return .properties(
      (details?.properties ?? []).map { property in
        WaypointField(
          key: property.key, label: property.label,
          value: waypointPropertyValue(property, units: units, formatInstant: formatCutoffAt),
          href: waypointPropertyLink(property))
      })
  }
}
