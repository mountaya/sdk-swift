/// stretchAt is the stretch `distance` meters from the itinerary's start reads
/// (`geo.profile.stretch-at`): the one that starts at or before it and ends after it, so at a
/// boundary two stretches share the later one reads, the way a cursor moving forward reads it.
/// Where none starts there, the one that ends exactly at the distance keeps it, its own last meter
/// before a gap and the last meter of the itinerary; anywhere else, in a gap, before the first
/// stretch or past the last, none does.
///
/// The stretches are read as `curveSpans` states them, as the curve is painted: in distance order,
/// one of no length left out, and the earlier of two overlapping keeping the shared ground, which
/// is the start the stretch answered states. So the word a hover card names, the colour it shows
/// and the leg a cursor lights on a map are one answer.
public func stretchAt<Span: ProfileSpan>(_ stretches: [Span], distance: Double) -> Span? {
  var ending: Span?
  for span in curveSpans(stretches) {
    if distance >= span.from && distance < span.to { return span }
    if distance == span.to { ending = span }
  }
  return ending
}
