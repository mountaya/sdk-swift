import Foundation

/// TimeSliderRelease is what a time slider commits as a reader lets its thumb go
/// (`geo.layers.time-slider`): the instant to pin, which a layers selection pins
/// (`LayersSelectionEngine.setInstant(_:)`), or nil to pin none, so every surface that reads the
/// time follows the clock again.
///
/// It holds its pin as the seconds a `Date` holds (`pinTime`): Foundation keeps the layout of its
/// `Date` to itself, so a type holding one is laid out at run time and copied through its witnesses,
/// in every app, where a type holding its seconds is plain data.
public struct TimeSliderRelease: Sendable, Equatable {
  /// pinTime is the instant the release pins, in seconds from the reference date as a `Date` holds
  /// it, or nil where it pins none.
  var pinTime: Double?

  /// pin is the instant the release pins, or nil where it pins none.
  public var pin: Date? {
    pinTime.map { Date(timeIntervalSinceReferenceDate: $0) }
  }

  /// Creates the release pinning `pin`, or none.
  public init(pin: Date?) {
    pinTime = pin?.timeIntervalSinceReferenceDate
  }
}
