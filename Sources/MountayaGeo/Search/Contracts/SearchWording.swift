/// SearchWording is how a search result's title and second line are worded for a reader:
/// `resolveLabel` answers the word each wire value reads as, or `nil` or the empty string for a
/// value it has no word for, which then reads as the English title of the value (`POPULATED_PLACE`
/// as `Populated place`), and `units` states a distance and an elevation in the reader's system,
/// language and digits; with none they read in metric, in Latin digits.
///
/// The default words nothing: English titles of the wire values and metric figures. It is not
/// `Equatable`, since Swift compares no two functions.
public struct SearchWording: Sendable {
  /// units are the reader's units, or `nil` for metric in Latin digits.
  public var units: UnitPreferences?
  /// resolveLabel is the word a wire value reads as, or `nil` where the host has none. The last
  /// member, so it may trail.
  public var resolveLabel: @Sendable (SearchLabel) -> String?

  /// Creates the wording from the reader's units and the host's words.
  public init(
    units: UnitPreferences? = nil,
    resolveLabel: @escaping @Sendable (SearchLabel) -> String? = { _ in nil }
  ) {
    self.units = units
    self.resolveLabel = resolveLabel
  }
}
