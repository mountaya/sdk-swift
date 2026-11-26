/// placeSpans is the stretches a profile draws under its chart, its band strip and its section
/// chips, each where it stands, in the order given (`geo.profile.window-spans`), so the two cannot
/// disagree about a stretch at the edge of a zoomed window.
///
/// A stretch, read in order, is drawn only where it overlaps `window`, the whole itinerary where
/// none is given, its two ends in either order, and cut at the window's ends, so a band stays under
/// the stretch of curve it describes at any zoom. A stretch the window does not reach, one that
/// only touches an end of it, and one of no length, given or cut, are left out rather than clamped
/// onto the window's edge: a sliver of no width is still announced to a screen reader.
public func placeSpans<Span: ProfileSpan>(
  _ spans: [Span], totalDistance: Double, window: ProfileRange? = nil
) -> [PlacedSpan<Span>] {
  let shown = orderedWindow(window, totalDistance: totalDistance)
  return spans.enumerated().compactMap { index, span in
    let from = minimumNumber(span.from, span.to)
    let to = maximumNumber(span.from, span.to)
    if to <= shown.from || from >= shown.to { return nil }
    let start = profileX(from, totalDistance: totalDistance, window: window)
    let end = profileX(to, totalDistance: totalDistance, window: window)
    return end > start
      ? PlacedSpan(span: span, index: index, from: from, to: to, start: start, end: end) : nil
  }
}
