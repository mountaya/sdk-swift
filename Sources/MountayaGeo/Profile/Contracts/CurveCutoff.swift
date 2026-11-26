import Foundation

/// CurveCutoff is one pass of a place that publishes a cut-off, marked across a profile
/// (`geo.profile.curve-placement`): its key, the place, where it stands on the axis and across the
/// plot, and the instant by which the place must be left, carried unwritten, since writing it needs
/// a time zone only the caller holds. A cut-off needs no height, so one stands on an itinerary with
/// no elevation too.
///
/// Two are equal where they hold the same key, written alike, the same place, and the same numbers
/// and instant, as every value of the geo layer compares.
public struct CurveCutoff: Sendable, Hashable {
  /// key is unique per pass: `id#pass`, counting the place's passes from zero.
  public var key: String
  /// place is the place marked.
  public var place: ProfilePlace
  /// distance is the meters from the start of the itinerary.
  public var distance: Double
  /// x is how far across the plot the mark stands.
  public var x: Double
  /// cutoffAt is the instant by which the place must be left.
  public var cutoffAt: Date

  /// Creates a cut-off from its key, its place, its distance, where it stands and its instant.
  public init(key: String, place: ProfilePlace, distance: Double, x: Double, cutoffAt: Date) {
    self.key = key
    self.place = place
    self.distance = distance
    self.x = x
    self.cutoffAt = cutoffAt
  }

  /// Two cut-offs are equal where every member is the same, the instants as the same number of
  /// seconds.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.key, rhs.key) && lhs.place == rhs.place && sameNumber(lhs.distance, rhs.distance)
      && sameNumber(lhs.x, rhs.x)
      && sameNumber(
        lhs.cutoffAt.timeIntervalSinceReferenceDate, rhs.cutoffAt.timeIntervalSinceReferenceDate)
  }

  /// hash feeds every member, each number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(key)
    hasher.combine(place)
    hasher.combine(sameNumber: distance)
    hasher.combine(sameNumber: x)
    hasher.combine(sameNumber: cutoffAt.timeIntervalSinceReferenceDate)
  }
}
