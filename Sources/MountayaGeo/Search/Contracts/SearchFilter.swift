import MountayaClient

/// SearchFilter is which part of a search's results a reader asks to see, in the order a surface
/// offers them: everything, then one filter per kind of thing a reader looks for. Each narrowing
/// filter shows the sections its reader means by it, and every section is under exactly one of
/// them.
public enum SearchFilter: String, CaseIterable, Sendable {
  /// all is every section.
  case all
  /// itineraries is the itineraries and the collections, a collection being a set of itineraries.
  case itineraries
  /// places is the places, the points of interest and the named ways, one idea of a place.
  case places
  /// zones is the zones.
  case zones

  /// id is the filter's id, as a surface and the contract name it.
  public var id: String { rawValue }

  /// targets are the search targets whose sections the filter shows.
  public var targets: Set<DataSchema.SearchTarget> {
    switch self {
    case .all: return [.places, .pois, .ways, .itineraries, .collections, .zones]
    case .itineraries: return [.itineraries, .collections]
    case .places: return [.places, .pois, .ways]
    case .zones: return [.zones]
    }
  }
}
