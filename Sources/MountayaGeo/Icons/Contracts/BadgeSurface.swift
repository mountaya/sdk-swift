/// BadgeSurface is where an amenity's badge stands, which decides what is written in its place
/// where the installed set cannot draw its glyph (`badgeFallback(_:on:)`).
public enum BadgeSurface: String, Sendable, Hashable, CaseIterable {
  /// cell is a table's cell, with room for the amenity's name.
  case cell
  /// stack is a profile's narrow stack of badges, with room for a letter.
  case stack
  /// labelled is beside a label of its own, which names the amenity already.
  case labelled
}
