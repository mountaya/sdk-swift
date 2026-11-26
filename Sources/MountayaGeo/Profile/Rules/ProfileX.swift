/// profileViewBox is the width and the height of the square a profile is drawn in, the
/// `viewBox` `geo/profile-plot-scale.json` declares: a position in it is also a percentage of the
/// box the square is stretched into, so a pin, a band and the curve align by construction.
public let profileViewBox: Double = 100

/// profileTopInset is the headroom above a profile's ceiling, in the square's units, the `topInset`
/// `geo/profile-plot-scale.json` declares, so a summit is not flush against the frame.
public let profileTopInset: Double = 6

/// profileBottomInset is the room below a profile's floor, in the square's units, the
/// `bottomInset` `geo/profile-plot-scale.json` declares, so a valley reads as a floor.
public let profileBottomInset: Double = 4

/// profileBaseline is how far down the square a profile's floor is drawn, `profileViewBox` less
/// `profileBottomInset`, the `baseline` `geo/profile-plot-scale.json` declares.
public let profileBaseline: Double = profileViewBox - profileBottomInset

/// profileX is where a profile draws `meters` from the start of the itinerary across its square
/// (`geo.profile.plot-scale`): the window's start at 0 and its end at `profileViewBox`, a distance
/// outside the window held to the frame. The window is the whole itinerary, `0` to
/// `totalDistance`, where none is given, and is read in order; a window or an itinerary of no
/// length draws every distance at 0.
///
/// The position is rounded to a thousandth of a unit, a half up, finer than any screen resolves.
public func profileX(_ meters: Double, totalDistance: Double, window: ProfileRange? = nil) -> Double
{
  let span = orderedWindow(window, totalDistance: totalDistance)
  guard span.to > span.from else { return 0 }
  let fraction = (meters - span.from) / (span.to - span.from)
  return plotUnit(clampNumber(fraction, to: 0...1) * profileViewBox)
}

/// projectX is where a profile's curve draws `meters` across its square, the way `profileX`
/// places it but never held to the frame, so a curve zoomed into a window leaves the frame at the
/// ground's own slope. `span` is read as given, in order.
func projectX(_ meters: Double, span: ProfileRange) -> Double {
  let width = span.to - span.from
  return width > 0 ? plotUnit((meters - span.from) / width * profileViewBox) : 0
}

/// orderedWindow is the window a profile is drawn over, in order: the whole itinerary, from 0 to
/// `totalDistance`, where none is given.
func orderedWindow(_ window: ProfileRange?, totalDistance: Double) -> ProfileRange {
  guard let window else { return ProfileRange(from: 0, to: totalDistance) }
  return ProfileRange(
    from: minimumNumber(window.from, window.to), to: maximumNumber(window.from, window.to))
}

/// plotUnit is a position in a profile's square rounded to a thousandth of a unit, a half up.
func plotUnit(_ value: Double) -> Double {
  roundHalfUp(value * 1_000) / 1_000
}
