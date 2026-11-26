/// minDomainSpanMeters is the narrowest elevation range a profile is drawn against, the
/// `minSpanMeters` `geo/profile-domain.json` declares: without it an itinerary that climbs four
/// meters over ten kilometers is drawn as a mountain, its curve filling the plot with its own
/// noise.
public let minDomainSpanMeters: Double = 50

/// emptyElevationDomain is the range a profile with no elevation is drawn against, 0 to 50 m, the
/// `emptyDomain` `geo/profile-domain.json` declares, so a frame drawn before the data arrives is the
/// frame it keeps.
public let emptyElevationDomain = ElevationDomain(min: 0, max: minDomainSpanMeters)

/// domainRoundingSteps is how coarsely a profile's elevation domain is rounded outward by its span,
/// the `roundingSteps` `geo/profile-domain.json` declares: by 10 m where the widened span is at most
/// 200 m, by 50 m where it is at most 1,000 m, and by 100 m past that, so an alpine profile reads
/// against hundred-meter lines and a coastal one against ten-meter lines.
public let domainRoundingSteps = [
  DomainRoundingStep(stepMeters: 10, uptoSpanMeters: 200),
  DomainRoundingStep(stepMeters: 50, uptoSpanMeters: 1_000),
  DomainRoundingStep(stepMeters: 100, uptoSpanMeters: nil),
]

/// extentDomain is the elevation range a stated extent is drawn against (`geo.profile.domain`):
/// widened to at least `minDomainSpanMeters` about its middle and rounded outward, its floor down
/// and its ceiling up, to a multiple of the step `domainRoundingSteps` gives its widened span, so it
/// is always wider than a point. An extent with either bound missing is `emptyElevationDomain`.
public func extentDomain(min lowest: Double?, max highest: Double?) -> ElevationDomain {
  guard let lowest, let highest else { return emptyElevationDomain }
  let measured = highest - lowest
  let padding = maximumNumber(0, minDomainSpanMeters - measured) / 2
  let step = roundingStep(maximumNumber(measured, minDomainSpanMeters))
  let floor = ((lowest - padding) / step).rounded(.down) * step
  let ceiling = ((highest + padding) / step).rounded(.up) * step
  return ElevationDomain(min: floor, max: ceiling > floor ? ceiling : floor + step)
}

/// The step a widened span is rounded by: the first of `domainRoundingSteps` whose ceiling it does
/// not pass, and the last for any other.
private func roundingStep(_ span: Double) -> Double {
  for step in domainRoundingSteps {
    guard let upto = step.uptoSpanMeters else { return step.stepMeters }
    if span <= upto { return step.stepMeters }
  }
  return domainRoundingSteps.last?.stepMeters ?? minDomainSpanMeters
}
