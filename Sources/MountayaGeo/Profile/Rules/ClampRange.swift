/// minRangeSpanMeters is the narrowest window a profile is drawn over, the `minSpanMeters`
/// `geo/profile-window-clamp.json` declares and the `minRangeSpanMeters` `geo/profile-totals.json`
/// declares: a window narrower than a hundred meters shows a curve no reader can follow.
public let minRangeSpanMeters: Double = 100

/// clampRange is the window a profile draws for the one asked of it (`geo.profile.window-clamp`):
/// ordered, held inside the itinerary, and never narrower than `minRangeSpanMeters`, a narrower one
/// widened forward from its start where the itinerary has room and back from the itinerary's end
/// where it does not, so a window dragged to the very end stays there. An end that is no number
/// reads as the itinerary's end on that side, `from` its start and `to` its finish, and an infinite
/// end is held to the itinerary like any other. An itinerary shorter than the minimum is its own
/// whole width, and one of no length, or whose length is no number, has a window of no length at 0.
///
/// A handle dragged past its partner swaps the two rather than inverting the window, and a window
/// a caller states comes back as the one the chart will draw, so a controlled window and one the
/// element moves itself behave the same.
public func clampRange(_ window: ProfileRange, totalDistance: Double) -> ProfileRange {
  let span = totalDistance.isNaN ? 0 : maximumNumber(0, totalDistance)
  guard span > 0 else { return ProfileRange(from: 0, to: 0) }
  let start = window.from.isNaN ? 0 : window.from
  let end = window.to.isNaN ? span : window.to
  let low = maximumNumber(0, minimumNumber(start, end))
  let high = minimumNumber(span, maximumNumber(start, end))
  let minimum = minimumNumber(minRangeSpanMeters, span)
  if high - low >= minimum { return ProfileRange(from: low, to: high) }
  let from = maximumNumber(0, minimumNumber(low, span - minimum))
  return ProfileRange(from: from, to: from + minimum)
}
