/// DomainRoundingStep is how coarsely a profile's elevation domain is rounded outward, by its span:
/// to a multiple of `stepMeters` where the widened span is at most `uptoSpanMeters`, and past every
/// bounded step, the last (`geo.profile.domain`).
///
/// Two are equal where they hold the same numbers, as every value of the geo layer compares.
public struct DomainRoundingStep: Sendable, Hashable {
  /// stepMeters is the multiple the domain's ends are rounded outward to.
  public var stepMeters: Double
  /// uptoSpanMeters is the widest span this step rounds, nil for the step past every other.
  public var uptoSpanMeters: Double?

  /// Creates a step from its multiple and the widest span it rounds.
  public init(stepMeters: Double, uptoSpanMeters: Double?) {
    self.stepMeters = stepMeters
    self.uptoSpanMeters = uptoSpanMeters
  }

  /// Two steps are equal where their numbers are the same, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.stepMeters, rhs.stepMeters) && sameNumber(lhs.uptoSpanMeters, rhs.uptoSpanMeters)
  }

  /// hash feeds the numbers as the same-number relation reads them.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: stepMeters)
    hasher.combine(sameNumber: uptoSpanMeters)
  }
}
