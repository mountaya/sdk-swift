/// DurationSplit is a duration as a reader is shown it: whole hours, never carried into days, and
/// the minutes past them, from 0 to 59.
public struct DurationSplit: Sendable, Hashable {
  /// hours is the whole hours.
  public var hours: Int
  /// minutes is the minutes past `hours`, from 0 to 59.
  public var minutes: Int

  /// Creates a split from its hours and its minutes.
  public init(hours: Int, minutes: Int) {
    self.hours = hours
    self.minutes = minutes
  }
}
