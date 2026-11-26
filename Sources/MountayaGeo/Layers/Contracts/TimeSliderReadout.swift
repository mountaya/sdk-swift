import Foundation

/// TimeSliderReadout is what a time slider's thumb reads at a stop (`geo.layers.time-readout`): the
/// instant the stop stands for, and its offset from the stop of the clock's reading as a word of
/// the elements' `layers` section, counted where it counts hours or days. A slider writes the
/// instant through the locale services, then ` · `, then the word, counted through
/// `countedText(_:count:language:)`, and the word alone where the stop stands for no instant.
///
/// Two are equal where every member is, a word by its scalars. It holds its instant as the seconds a
/// `Date` holds, as `TimeSliderRelease` holds its pin.
public struct TimeSliderReadout: Sendable, Equatable {
  /// instantTime is the instant the stop stands for, in seconds from the reference date as a `Date`
  /// holds it, or nil for a stop that stands for none.
  var instantTime: Double?

  /// instant is the instant the stop stands for, or nil for a stop that stands for none.
  public var instant: Date? {
    instantTime.map { Date(timeIntervalSinceReferenceDate: $0) }
  }
  /// word is the path of the offset's word: `layers.timeNow` at the clock's reading,
  /// `layers.timeHoursAhead` or `layers.timeHoursAgo` under a day, and `layers.timeDaysAhead` or
  /// `layers.timeDaysAgo` from a day on.
  public var word: String
  /// count is the hours or the days the counted word takes, never below one, or nil for
  /// `layers.timeNow`.
  public var count: Int?

  /// Creates the readout of `instant`, its offset read as the word at `word` counting `count`.
  public init(instant: Date?, word: String, count: Int?) {
    instantTime = instant?.timeIntervalSinceReferenceDate
    self.word = word
    self.count = count
  }

  /// Two readouts are equal where they read the same instant and the same word, counting the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.instantTime == rhs.instantTime && sameText(lhs.word, rhs.word) && lhs.count == rhs.count
  }
}
