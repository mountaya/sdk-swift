/// WaypointSummaryWords is the copy a place's one-line summary is assembled from, in the reader's
/// language: the word for a place that is equipped, and the clause each timing fact reads in. The
/// words are the caller's; only the assembly is the rule.
///
/// It holds functions, which Swift does not compare, so two are never compared: no rule needs to.
public struct WaypointSummaryWords: Sendable {
  /// amenities is the word that says a place is equipped, the one a card heads its services with:
  /// `Services`.
  public var amenities: String
  /// openingHours is the clause of the opening hours, handed them as the place writes them:
  /// `open 8:00 to 18:00`.
  public var openingHours: @Sendable (_ hours: String) -> String
  /// cutoffAt is the clause of the cut-off, handed it as the caller's formatter spells it:
  /// `cut-off 09:00`.
  public var cutoffAt: @Sendable (_ moment: String) -> String
  /// stop is the clause of the planned stop, handed it as the duration formatter states it:
  /// `stop 15m`.
  public var stop: @Sendable (_ elapsed: String) -> String

  /// Creates the copy from the word for an equipped place and the three timing clauses.
  public init(
    amenities: String,
    openingHours: @escaping @Sendable (_ hours: String) -> String,
    cutoffAt: @escaping @Sendable (_ moment: String) -> String,
    stop: @escaping @Sendable (_ elapsed: String) -> String
  ) {
    self.amenities = amenities
    self.openingHours = openingHours
    self.cutoffAt = cutoffAt
    self.stop = stop
  }
}
