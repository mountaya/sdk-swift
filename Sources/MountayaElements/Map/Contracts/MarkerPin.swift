/// MarkerPin is what a marker given no view of its own is drawn as: a disc of its diameter in its
/// fill, ringed, with a glyph or a dot at its centre (`map.marker.pin`).
struct MarkerPin: Sendable, Hashable {
  /// Centre is what the disc carries at its centre.
  enum Centre: Sendable, Hashable {
    /// glyph is the marker's glyph, of the glyph set the map draws with, in a square of `size`
    /// pixels, in `color`.
    case glyph(String, size: Double, color: String)
    /// dot is a dot of diameter `size` pixels in `color`, where the marker names no glyph or the set
    /// cannot draw the one it names.
    case dot(size: Double, color: String)
  }

  /// diameter is the disc's diameter, its ring included, in pixels.
  let diameter: Double
  /// fill is the disc's colour, the marker's own, or nil for the map's accent.
  let fill: String?
  /// ringColor and ringWidth are the ring around the disc.
  let ringColor: String
  /// ringWidth is the ring's width, in pixels.
  let ringWidth: Double
  /// centre is what the disc carries at its centre.
  let centre: Centre
}
