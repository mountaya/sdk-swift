import MountayaGeo

/// GeometrySlot is one of the three geometries a map draws from data over what it holds: the
/// `preview` of an itinerary being planned, the `highlight` of what a reader picked, and the
/// `emphasis` of the leg a reader points at (`map.geometry.slots`).
///
/// Each holds one geometry in a colour, apart from the others, so writing one never clears
/// another. Each draws from a source of its own as the itinerary's cased line, the highlight alone
/// adding a circle for a point (`map.geometry.layers`).
public enum GeometrySlot: String, CaseIterable, Sendable {
  /// preview is an itinerary being planned, drawn just above the itinerary lines.
  case preview
  /// highlight is what a reader picked, a result from a list, drawn above every content band.
  case highlight
  /// emphasis is the leg a reader points at, drawn just above the itinerary lines.
  case emphasis

  /// color is the colour the slot draws in where a call names none.
  var color: String {
    switch self {
    case .preview: "#2b8a3e"
    case .highlight: "#f59f00"
    case .emphasis: "#e9501e"
    }
  }

  /// rank is the band the slot draws at: the highlight at the chrome band, as what the reader is
  /// doing, and the preview and the emphasis at the band just above the itinerary lines they
  /// accompany, so the order the calls arrive in never stacks one under the route it lights.
  var rank: Int {
    switch self {
    case .highlight: LayerRank.chrome.rank
    case .preview, .emphasis: LayerRank.itineraryFocus.rank
    }
  }

  /// sourceId is the id of the source the slot draws from, `mountaya-` then its name.
  var sourceId: String { "mountaya-\(rawValue)" }
}
