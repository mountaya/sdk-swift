import MountayaGeo

/// readRoadAccessStripeImageId answers the kind of restricted stretch whose stripe pattern the
/// image id `id` names, or nil for an id that names none.
///
/// An id names one where it is `road-access-stripe-` followed by a kind's id, as the stripe layer
/// beside an itinerary's line names it (`roadAccessLayersOf(_:isShown:)`), the whole id read
/// scalar by scalar. An id under the prefix whose tail is no kind is left missing, so no stretch
/// is ever striped in a colour no kind has, and any other id is left to the map's other answers.
func readRoadAccessStripeImageId(_ id: String) -> RoadAccessKind? {
  let scalars = Array(id.unicodeScalars)
  let prefix = Array(roadAccessStripeImagePrefix.unicodeScalars)
  guard scalars.starts(with: prefix) else { return nil }
  let tail = String(String.UnicodeScalarView(scalars.dropFirst(prefix.count)))
  return RoadAccessKind.allCases.first { sameText($0.id, tail) }
}
