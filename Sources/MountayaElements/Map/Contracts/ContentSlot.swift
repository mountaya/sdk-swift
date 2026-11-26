import MountayaGeo

/// ContentSlot is one place a map holds content in, which draws one request at a time: the
/// itinerary and the collection asked for by id, the itineraries and zones switched on, the classic
/// overlay, an enrichment by its slug, a specification an app draws under a name of its own, a Data
/// API result by its id, a geometry slot, and the result a reader picked from a search.
///
/// Each kind of content is a slot of its own, so drawing one never clears another, and a slot asked
/// for again draws in its place (`map.slots.latest-request`, `map.layers.keys`). A name and a slug
/// are compared by their scalars.
enum ContentSlot: Sendable, Equatable {
  /// itinerary is the itinerary drawn by id.
  case itinerary
  /// collection is the collection drawn by id.
  case collection
  /// itineraries is the itineraries of the credential's scope, switched on.
  case itineraries
  /// zones is the zones of the credential's scope, switched on.
  case zones
  /// overlay is the classic overlay, of which a map draws one at a time.
  case overlay
  /// enrichment is the enrichment of a slug, of which a map draws any number, stacked.
  case enrichment(String)
  /// specification is a specification an app drew under a name of its own.
  case specification(String)
  /// analysis is a Data API result drawn under its id (`map.analysis.slots`).
  case analysis(String)
  /// geometry is one of the preview, the highlight and the emphasis (`map.geometry.slots`).
  case geometry(GeometrySlot)
  /// searchHighlight is the result a reader picked from a search (`map.search.result-highlight`).
  case searchHighlight

  /// Two slots are one where they are of one kind and name the same, by its scalars.
  static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.itinerary, .itinerary), (.collection, .collection), (.itineraries, .itineraries),
      (.zones, .zones), (.overlay, .overlay), (.searchHighlight, .searchHighlight):
      return true
    case (.enrichment(let a), .enrichment(let b)), (.specification(let a), .specification(let b)),
      (.analysis(let a), .analysis(let b)):
      return sameText(a, b)
    case (.geometry(let a), .geometry(let b)):
      return a == b
    default:
      return false
    }
  }
}
