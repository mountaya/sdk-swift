import Foundation
import MountayaClient

/// waypointHeadline is the line a card states under a waypoint's name: what its author wrote about
/// it, its description past the white space at its ends, or, where it has none or only white space,
/// what `waypointSummary(_:words:units:formatCutoffAt:)` assembles from its record. A description
/// always wins, even a terse one, since an author who wrote one chose it over anything a summary
/// could say.
public func waypointHeadline(
  _ waypoint: RestSchema.ItineraryWaypoint,
  words: WaypointSummaryWords,
  units: UnitPreferences,
  formatCutoffAt: ((Date) -> String)? = nil
) -> String? {
  let description = waypoint.description.map(trimWhiteSpace) ?? ""
  if !description.isEmpty { return description }
  return waypointSummary(waypoint, words: words, units: units, formatCutoffAt: formatCutoffAt)
}
