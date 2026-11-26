import Foundation
import MountayaClient

/// What parts the summary's two clauses: a middle dot between two spaces.
private let summarySeparator = " · "

/// waypointSummary is what a waypoint says about itself in one line when its author wrote no
/// description: two clauses at most, whether it is equipped and when it can be used, joined by a
/// middle dot between two spaces, `Services · stop 15m`. The services themselves are repeated as
/// badges directly beneath, so the line names none of them.
///
/// The first clause is `words.amenities` where the place lists any service. The second is one
/// timing fact: its opening hours where its contact states some, else its cut-off where
/// `formatCutoffAt` can spell one, else its planned stop as `formatDuration(_:units:)` states it
/// for `units`, where it is one minute or more. A cut-off is an instant only the caller knows the
/// zone to print in, so the caller supplies its formatter as it supplies the words; with none, the
/// clause falls through to the stop. Nil where neither clause has anything to say.
public func waypointSummary(
  _ waypoint: RestSchema.ItineraryWaypoint,
  words: WaypointSummaryWords,
  units: UnitPreferences,
  formatCutoffAt: ((Date) -> String)? = nil
) -> String? {
  var clauses: [String] = []
  if !waypoint.amenities.isEmpty { clauses.append(words.amenities) }
  if let timing = timingClause(waypoint, words: words, units: units, formatCutoffAt: formatCutoffAt)
  {
    clauses.append(timing)
  }
  return clauses.isEmpty ? nil : clauses.joined(separator: summarySeparator)
}

/// The one timing fact the summary states: the opening hours, else the cut-off, else the stop.
private func timingClause(
  _ waypoint: RestSchema.ItineraryWaypoint,
  words: WaypointSummaryWords,
  units: UnitPreferences,
  formatCutoffAt: ((Date) -> String)?
) -> String? {
  if let openingHours = waypoint.contact?.opening_hours ?? nil, !openingHours.isEmpty {
    return words.openingHours(openingHours)
  }
  if let cutoffAt = waypoint.timing?.cutoff_at ?? nil, let formatCutoffAt {
    return words.cutoffAt(formatCutoffAt(cutoffAt))
  }
  // A stop that rounds to no minute has no spelling, and a clause around none is a bare word.
  let stop = formatDuration((waypoint.timing?.stop_duration ?? nil).map(Double.init), units: units)
  return stop.isEmpty ? nil : words.stop(stop)
}
