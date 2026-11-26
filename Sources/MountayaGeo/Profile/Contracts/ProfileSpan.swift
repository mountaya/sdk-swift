/// ProfileSpan is anything that stands on an itinerary's distance axis between two distances: a
/// window, a coloured stretch of a profile's curve, a classified stretch and a table's row. The
/// rules that place, paint and read stretches take any of them, so a stretch keeps its own members
/// through them.
public protocol ProfileSpan: Sendable {
  /// from is where the span starts, in meters from the start of the itinerary.
  var from: Double { get set }
  /// to is where the span ends, in meters from the start of the itinerary.
  var to: Double { get set }
}
