import MountayaClient

/// readItineraryDirectionsSteps reads the steps of a REST directions segment into the one
/// vocabulary every navigation rule reads, and refuses the list whole where it does not tile the
/// segment's geometry (`geo.navigation.steps`).
///
/// A maneuver is read as written, and one REST does not spell, the Data API's SCREAMING_SNAKE
/// included, as `unknown`. An empty name and the `-` the API writes for an unnamed way read as no
/// name, and every other member is read as sent. A list is refused, never repaired, unless its
/// ranges cover the geometry once in travel order.
///
/// `steps` is the segment's `steps` as REST sends them, nil for a segment with none, a
/// `linestring` one; `coordinateCount` is the number of vertices in the segment's geometry, the
/// index basis of the steps. A refused list reads as no steps, and the segment is followed as one
/// with none.
public func readItineraryDirectionsSteps(
  _ steps: [RestSchema.ItineraryDirectionsStep]?, coordinateCount: Int
) -> NavigationStepsReading {
  stepsReading(
    (steps ?? []).map { step in
      NavigationStep(
        fromIndex: step.from_index,
        toIndex: step.to_index,
        maneuver: maneuverOf(step.type),
        name: wayName(step.name),
        distance: step.distance,
        duration: step.duration,
        exitNumber: step.exit_number
      )
    },
    coordinateCount: coordinateCount
  )
}
