import MountayaClient

/// ItineraryStroke is one of the three strokes an itinerary drawn from data is drawn with, as its
/// tiles are (`geo.style.itinerary-stroke`): the solid line, the provisional dashed line, and the
/// casing beneath either.
///
/// A line's colour is a literal MapLibre parses, `#2b8a3e`, or an expression it reads from each
/// feature, `["get", "mtyaColor"]`, so one layer draws a source holding several itineraries. The
/// casing is drawn in the paint's own colour and takes none of its caller's.
///
/// Two are equal where they are the same stroke in the same colour, compared as Geo compares JSON,
/// a number by the same-number relation and a text by its scalars, and equal strokes hash alike.
public enum ItineraryStroke: Sendable, Hashable {
  /// line is the solid stroke, in `color`.
  case line(color: JSONValue)
  /// dashed is the provisional stroke, in `color`: a suggested alternative, an unchosen candidate
  /// or a draft not yet confirmed, dashed and muted so it reads as secondary without reading as
  /// another kind of line.
  case dashed(color: JSONValue)
  /// casing is the halo beneath a stroke, wider than it at every stop, which keeps the line legible
  /// over relief and over an overlay.
  case casing

  /// Two strokes are equal where they are the same stroke in the same colour.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.line(let left), .line(let right)), (.dashed(let left), .dashed(let right)):
      return sameJson(left, right)
    case (.casing, .casing):
      return true
    default:
      return false
    }
  }

  /// hash feeds the stroke and its colour as Geo compares JSON.
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .line(let color):
      hasher.combine(0)
      hasher.combine(sameJson: color)
    case .dashed(let color):
      hasher.combine(1)
      hasher.combine(sameJson: color)
    case .casing:
      hasher.combine(2)
    }
  }
}
