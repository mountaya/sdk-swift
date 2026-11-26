/// curveSpans is stretches of an itinerary in distance order with no overlap, the one reading the
/// gradient a curve is painted with and every lookup of a distance share: each read in order, one of
/// no length left out, and where two would share ground the earlier keeps it, the later starting
/// where the earlier ends. A stretch keeps its own members through it, so a classified stretch keeps
/// its word and a table's row its own.
///
/// Stretches that start at one distance keep the order they are given in.
func curveSpans<Span: ProfileSpan>(_ stretches: [Span]) -> [Span] {
  let ordered = stretches.enumerated().compactMap { listed, stretch -> (Int, Span)? in
    var span = stretch
    span.from = minimumNumber(stretch.from, stretch.to)
    span.to = maximumNumber(stretch.from, stretch.to)
    return span.to > span.from ? (listed, span) : nil
  }
  .sorted { a, b in
    a.1.from == b.1.from ? a.0 < b.0 : a.1.from < b.1.from
  }
  var resolved: [Span] = []
  var cursor = -Double.infinity
  for (_, span) in ordered {
    let from = maximumNumber(span.from, cursor)
    if span.to <= from { continue }
    var kept = span
    kept.from = from
    resolved.append(kept)
    cursor = span.to
  }
  return resolved
}
