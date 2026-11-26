/// profileY is where a profile draws an elevation down its square (`geo.profile.plot-scale`),
/// upside down as a screen counts: the domain's ceiling at `profileTopInset` from the top and its
/// floor at `profileBaseline`, an elevation outside the domain held to the frame, and every
/// elevation half way between the two where the domain has no span.
///
/// The position is rounded to a thousandth of a unit, a half up, finer than any screen resolves.
public func profileY(_ elevation: Double, domain: ElevationDomain) -> Double {
  let span = domain.max - domain.min
  let fraction = span > 0 ? clampNumber((elevation - domain.min) / span, to: 0...1) : 0.5
  return plotUnit(profileTopInset + (1 - fraction) * (profileBaseline - profileTopInset))
}
