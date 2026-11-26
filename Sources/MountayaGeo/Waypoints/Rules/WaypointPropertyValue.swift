import Foundation
import MountayaClient

/// The decimals a `number` field keeps at most, every locale's own for a plain number.
private let numberFieldFractionDigits = 3

/// waypointPropertyValue is how a place's custom field reads, by the format its author declared
/// (`geo.profile.waypoint-property-value`), since `3600` is a duration, a distance or a number by
/// what its author meant and a renderer guessing from the digits is right two times in three.
///
/// A `duration`, a `distance` and a `number` whose value reads as a finite number
/// (`readNumber(_:)`) are written by the formatters for `units`: the duration from seconds
/// (`formatDuration(_:units:)`), the distance from meters in the reader's system
/// (`formatDistance(_:units:)`), and the number grouped as the language groups it, with at most
/// three decimals (`formatNumber(_:locale:maximumFractionDigits:)`). A `date` is an instant, written
/// only by `formatInstant`, since only the caller holds the time zone to write it in: its value is
/// read by the client's anchor, `parseTimestamp(_:)`, as every timestamp the wire carries is read,
/// and one that names no real instant, a day past its month's last or a second of 60, reads as
/// written. Any other field, a `text` and a `url` among them, and a value its format cannot read,
/// reads as written.
public func waypointPropertyValue(
  _ property: WaypointDetails.Property,
  units: UnitPreferences,
  formatInstant: ((Date) -> String)? = nil
) -> String {
  let value = property.value
  guard let format = property.format else { return value }
  if sameText(format, .date) {
    guard let formatInstant, let instant = parseTimestamp(value) else { return value }
    return formatInstant(instant)
  }
  let number = readNumber(value)
  guard number.isFinite else { return value }
  if sameText(format, .duration) {
    return formatDuration(number, units: units)
  }
  if sameText(format, .distance) {
    return formatDistance(number, units: units)
  }
  if sameText(format, .number) {
    return formatNumber(
      number, locale: units.language, maximumFractionDigits: numberFieldFractionDigits)
  }
  return value
}
