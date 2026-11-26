/// LayerRank is a band of the stacking order the layers Mountaya draws above a base map take,
/// bottom to top, so a layer's place never depends on the order it was added in: an overlay added
/// after an itinerary never covers it, and a hillshade never shades the line it lies under.
///
/// A rank is a number, and the bands are spaced by ten but for the two that stand over an
/// itinerary's line, the geometry a map draws over it from data and its restricted stretches, so a
/// band a consumer adds between two neighbours takes a number between them, `LayerRank.poi.rank +
/// 2` between the points of interest and the itinerary's waypoints. A base map's own layers take
/// no rank and lie beneath every band.
public enum LayerRank: Int, CaseIterable, Sendable {
  /// hillshade is the shading of the terrain, at the bottom whatever its tiles' source layer.
  case hillshade = 10
  /// overlay is an overlay, and any tile layer whose source layer the rank table does not know.
  case overlay = 20
  /// streetviewCoverage is the coverage of street-level imagery.
  case streetviewCoverage = 30
  /// zone is a zone's area and its outline.
  case zone = 40
  /// itineraryLine is an itinerary's line.
  case itineraryLine = 50
  /// itineraryFocus is the geometry a map draws over its itineraries' lines from data, an
  /// itinerary being planned and the leg a reader points at, just above the lines and beneath
  /// their restricted stretches, so the order the calls arrive in never stacks it under the route
  /// it lights (`map.geometry.layers`).
  case itineraryFocus = 52
  /// itineraryRestriction is the stretches of an itinerary's line that follow a way restricting who
  /// may pass, drawn over the line they mark and beneath its direction, so a restriction is never
  /// painted under the line it qualifies and the direction still reads across it.
  case itineraryRestriction = 55
  /// itineraryDirection is the direction drawn along an itinerary's line.
  case itineraryDirection = 60
  /// streetviewCorridor is the corridor a street-level image may be dropped in.
  case streetviewCorridor = 70
  /// poi is a point of interest, above every line so a route never hides one.
  case poi = 80
  /// itineraryPoint is an itinerary's waypoint symbols.
  case itineraryPoint = 90
  /// chrome is what the reader is doing: a marker being dragged, a result highlighted from a list.
  case chrome = 100

  /// rank is the band's number: a layer of a greater rank draws above one of a lesser.
  public var rank: Int { rawValue }
}
